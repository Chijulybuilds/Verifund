// types/delivery.types.ts

export enum DeliveryType {
    GITHUB_REPO = "GITHUB_REPO",
    WEBSITE = "WEBSITE",
    FILE_UPLOAD = "FILE_UPLOAD",
    MOBILE_APP = "MOBILE_APP",
    MIXED = "MIXED"
}

export interface DeliverySubmission {
    escrowId: string;

    freelancerWallet: string;

    deliveryType: DeliveryType;

    deliveryReference?: string;

    repoOwner?: string;

    repoUrl?: string;

    repobranch?: string;

    reposha?: string;

    deploymentUrl?: string;

    notes?: string;

    uploadedFiles?: string[];

    uploadedAt: number;
}