"use strict";
// src/services/evidenceHasher.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.createEvidenceHash = createEvidenceHash;
var ethers_1 = require("ethers");
/**
 * Generates tamper-proof evidence hash.
 */
function createEvidenceHash(normalizedPayload) {
    return (0, ethers_1.keccak256)((0, ethers_1.toUtf8Bytes)(normalizedPayload));
}
