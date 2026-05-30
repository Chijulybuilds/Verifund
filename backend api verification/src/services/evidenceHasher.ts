// src/services/evidenceHasher.ts

import {
    keccak256,
    toUtf8Bytes
} from "ethers";

/**
 * Generates tamper-proof evidence hash.
 */
export function createEvidenceHash(
    normalizedPayload: string
): string {

    return keccak256(
        toUtf8Bytes(normalizedPayload)
    );
}