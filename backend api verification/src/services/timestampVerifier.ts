// services/timestampVerifier.ts

import { VerificationResult }
from "../types/verification.types";

export async function verifyDeliveryDeadline(
    uploadedAt: number,
    deadline: number
): Promise<VerificationResult> {

    if (uploadedAt >= deadline) {

        return {
            valid: false,

            score: 0,

            reason:
                "Delivery exceeded deadline",

           
        };
    }

    return {
        valid: true,

        score: 100
    };
}