// services/urlVerifier.ts

import axios from "axios";

import {
    VerificationResult
} from "../types/verification.types";

export async function verifyDeploymentUrl(
    url: string
): Promise<VerificationResult> {

    try {

        const response =
            await axios.get(url, {
                timeout: 5000
            });

        /**
         * Healthy deployment
         */
        if (response.status === 200) {

            return {
                valid: true,

                score: 100
            };
        }

        return {
            valid: false,

            score: 0,

            reason:
                "Deployment returned non-200 response"
        };

    } catch (error) {

        console.error(error);

        return {
            valid: false,

            score: 0,

            reason:
                "Deployment URL unreachable"
        };
    }
}