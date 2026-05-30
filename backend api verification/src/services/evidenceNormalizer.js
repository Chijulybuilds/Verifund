"use strict";
// src/services/evidenceNormalizer.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizeEvidence = normalizeEvidence;
/**
 * Creates deterministic canonical payload.
 *
 * IMPORTANT:
 * Same input must ALWAYS produce same output.
 */
function normalizeEvidence(payload) {
    var normalized = {
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
