// services/githubVerifier.ts
import axios from "axios";
import { VerificationResult } from "../types/verification.types";

export async function verifyGithubRepository(
    owner: string,
    repo: string,
    branch: string, 
    sha: string     
): Promise<VerificationResult> {
    try {
        let score = 0;
        const failures: string[] = [];

        /**
         * =====================================================
         * 1. VERIFY REPOSITORY EXISTS (Max: 20 Points)
         * =====================================================
         */
        const repoResponse = await axios.get(
            `https://api.github.com/repos/${owner}/${repo}`,
            { headers: { Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}` } }
        );

        if (repoResponse.status === 200) {
            score += 20;
        } else {
            failures.push("Repository could not be accessed.");
        }

        /**
         * =====================================================
         * 2. VERIFY AUTOMATED CI/CD BUILDS (Max: 30 Points)
         * =====================================================
         */
        let ciPassed = false;
        try {
            const checksResponse = await axios.get(
                `https://api.github.com/repos/${owner}/${repo}/commits/${branch}/check-runs`,
                { headers: { Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}` } }
            );

            const checkRuns = checksResponse.data.check_runs;
            // Check if any automated pipelines directly threw a 'failure' conclusion
            const hasFailedTests = checkRuns.some((run: any) => run.conclusion === "failure");

            if (checkRuns.length > 0 && !hasFailedTests) {
                score += 30;
                ciPassed = true;
            } else if (hasFailedTests) {
                failures.push("Automated CI/CD suite contains failing test builds.");
            } else {
                score += 15; // Partial credit if no CI actions are established yet
            }
        } catch (err) {
            failures.push("Could not recover workflow check-runs from GitHub.");
        }

        /**
         * =====================================================
         * 3. VERIFY PULL REQUEST STATUS (Max: 25 Points)
         * =====================================================
         */
        try {
            const prsResponse = await axios.get(
                `https://api.github.com/repos/${owner}/${repo}/pulls?state=closed`,
                { headers: { Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}` } }
            );

            const mergedPRs = prsResponse.data.filter((pr: any) => pr.merged_at !== null);
            if (mergedPRs.length > 0) {
                score += 25;
            } else {
                failures.push("No merged or formally reviewed Pull Requests located.");
            }
        } catch (err) {
            failures.push("Failed pulling workflow development logs.");
        }

        /**
         * =====================================================
         * 4. INSPECT EXACT COMMIT DELIVERABLES (Max: 25 Points)
         * =====================================================
         */
        try {
            const commitDetails = await axios.get(
                `https://api.github.com/repos/${owner}/${repo}/commits/${sha}`,
                { headers: { Authorization: `Bearer ${process.env.GITHUB_API_TOKEN}` } }
            );

            const totalChanges = commitDetails.data.stats?.total || 0;
            const filesChanged = commitDetails.data.files?.length || 0;

            if (totalChanges > 0 && filesChanged > 0) {
                score += 25;
            } else {
                failures.push("The target cryptographic commit hash contains empty file additions.");
            }
        } catch (err) {
            failures.push("Target deployment SHA not found inside remote workspace history.");
        }

        /**
         * =====================================================
         * EVALUATE PASSED STATUS
         * =====================================================
         */
        return {
            valid: score >= 75, // Base threshold requirement for individual milestone safety
            score,
            reason: failures.length > 0 ? failures.join(" | ") : "All GitHub checkpoints successfully cleared."
        };

    } catch (error: any) {
        console.error(error);
        return {
            valid: false,
            score: 0,
            reason: error.response?.data?.message || "GitHub repository verification failed completely."
        };
    }
}
