// src/services/evidenceNormalizer.ts

export interface EvidencePayload {
    repoUrl?: string;
    deploymentUrl?: string;
    uploadedFiles?: string[];
    notes?: string;
    deliveryReferences?: string;
    uploadedAt: number;
    freelancerWallet: string;
    escrowId: string;
}

/**
 * Creates deterministic canonical payload.
 *
 * IMPORTANT:
 * Same input must ALWAYS produce same output.
 */
export function normalizeEvidence(
    payload: EvidencePayload
): string {

    const normalized = {
        repoUrl: payload.repoUrl || "",
        deploymentUrl: payload.deploymentUrl || "",
        uploadedFiles: payload.uploadedFiles || [],
        notes: payload.notes || "",
        deliveryReferences: payload.deliveryReferences || "",
        uploadedAt: payload.uploadedAt,
        freelancerWallet: payload.freelancerWallet.toLowerCase(),
        escrowId: payload.escrowId
    };

    return JSON.stringify(normalized);
}