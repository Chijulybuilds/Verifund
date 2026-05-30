// services/disputeEngine.ts

import {
    DeliverySubmission
} from "../types/delivery.types";

import {
    VerificationChecks
} from "../types/verification.types";

import {
    verifyGithubRepository
} from "./githubVerifier";

import {
    verifyDeploymentUrl
} from "./urlVerifier";

import {
    verifyDeliveryDeadline
} from "./timestampVerifier";

import {
    verifyDeliverables
} from "./deliverableVerifier";

export async function runDisputeVerification(
    submission: DeliverySubmission,
    checks: VerificationChecks,
    deadline: number
) {

    let totalChecks = 0;
    let passedChecks = 0;

    const results: any = {};

    /**
     * =========================================================
     * GITHUB CHECK
     * =========================================================
     */

    if (
        checks.github &&
        submission.repoOwner &&
        submission.repoUrl &&
        submission.repobranch &&
        submission.reposha
    ) {
        totalChecks++;

        const githubResult =
            await verifyGithubRepository(
                submission.repoOwner,
                submission.repoUrl,
                submission.repobranch,
                submission.reposha
            );

        results.github = githubResult;

        if (githubResult.valid) {
            passedChecks++;
        }
    }

    /**
     * =========================================================
     * DEPLOYMENT CHECK
     * =========================================================
     */

    if (
        checks.deployment &&
        submission.deploymentUrl
    ) {
        totalChecks++;

        const deploymentResult =
            await verifyDeploymentUrl(
                submission.deploymentUrl
            );

        results.deployment = deploymentResult;

        if (deploymentResult.valid) {
            passedChecks++;
        }
    }

    /**
     * =========================================================
     * FILE CHECK
     * =========================================================
     */

    if (
        checks.files &&
        submission.uploadedFiles
    ) {
        totalChecks++;

        const filesResult =
            await verifyDeliverables(
                submission.uploadedFiles
            );

        results.files = filesResult;

        if (filesResult.valid) {
            passedChecks++;
        }
    }

    /**
     * =========================================================
     * DEADLINE CHECK
     * =========================================================
     */

    if (checks.deadline) {

        totalChecks++;

        const deadlineResult =
            await verifyDeliveryDeadline(
                submission.uploadedAt,
                deadline
            );

        results.deadline = deadlineResult;

        if (deadlineResult.valid) {
            passedChecks++;
        }
    }

    /**
     * =========================================================
     * DYNAMIC SCORE
     * =========================================================
     */

    const score =
        totalChecks === 0
            ? 0
            : Math.floor(
                (passedChecks * 100)
                /
                totalChecks
            );

    /**
     * =========================================================
     * FINAL VERDICT
     * =========================================================
     */

    const approved = score >= 90;

    return {
        approved,
        score,
        totalChecks,
        passedChecks,
        results
    };
}