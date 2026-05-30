// src/controllers/delivery.controller.ts

import { Request, Response } from "express";

import {
    normalizeEvidence
} from "../services/evidenceNormalizer";

import {
    createEvidenceHash
} from "../services/evidenceHasher";

import {
    storeEvidence
} from "../services/evidenceStorage";


export async function submitDelivery(
    req: Request,
    res: Response
) {

    try {

        const payload = {
            repoUrl: req.body.repoUrl,
            deploymentUrl: req.body.deploymentUrl,
            uploadedFiles: req.body.uploadedFiles,
            notes: req.body.notes,
            deliveryReference: req.body.deliveryReference,
            uploadedAt: Date.now(),
            freelancerWallet: req.body.freelancerWallet,
            escrowId: req.body.escrowId
        };

        /**
         * STEP 1:
         * Normalize evidence.
         */
        const normalized =
            normalizeEvidence(payload);

        /**
         * STEP 2:
         * Generate deterministic hash.
         */
        const evidenceHash =
            createEvidenceHash(normalized);

        /**
         * STEP 3:
         * Store evidence.
         */
        await storeEvidence(
            evidenceHash,
            normalized
        );

        return res.status(200).json({
            success: true,
            evidenceHash
        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false
        });
    }
}