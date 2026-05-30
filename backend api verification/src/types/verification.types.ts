// types/verification.types.ts

export interface VerificationChecks {
    github?: boolean;
    deployment?: boolean;
    files?: boolean;
    deadline?: boolean;
}

// types/verification.types.ts

export interface VerificationResult {
    valid: boolean;
    score: number;
    reason?: string;
}

export interface GithubVerificationResult
    extends VerificationResult {

    commitCount?: number;

    recentlyUpdated?: boolean;

    hasReadme?: boolean;

    deploymentDetected?: boolean;

    repoExists?: boolean;
}

export interface FileVerificationResult
    extends VerificationResult {

    fileHashes?: string[];
}