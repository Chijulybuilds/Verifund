// services/deliverableVerifier.ts

import crypto from "crypto";

import fs from "fs";

import mime from "mime-types";

import {
    VerificationResult
} from "../types/verification.types";

export async function verifyDeliverables(
    filePaths: string[]
): Promise<VerificationResult> {

    try {

        /**
         * Reject empty upload array
         */
        if (filePaths.length === 0) {

            return {
                valid: false,

                score: 0,

                reason:
                    "No uploaded files found"
            };
        }

        /**
         * Allowed file types
         */
        const allowedMimeTypes = [
            "application/zip",
            "application/x-zip-compressed",
            "application/pdf"
        ];

        /**
         * Max size:
         * 100MB
         */
        const MAX_SIZE =
            100 * 1024 * 1024;

        let validFiles = 0;

        /**
         * Validate all uploaded files
         */
        for (let i = 0; i < filePaths.length; i++) {

            const currentFile =
                filePaths[i];

            /**
             * File existence
             */
            if (!fs.existsSync(currentFile)) {
                continue;
            }

            const fileBuffer =
                fs.readFileSync(currentFile);

            /**
             * Reject empty files
             */
            if (fileBuffer.length === 0) {
                continue;
            }

            /**
             * Reject oversized files
             */
            if (fileBuffer.length > MAX_SIZE) {
                continue;
            }

            /**
             * MIME validation
             */
            const mimeType =
                mime.lookup(currentFile);

            if (
                !mimeType ||
                !allowedMimeTypes.includes(mimeType)
            ) {
                continue;
            }

            /**
             * Generate file hash
             */
            crypto
                .createHash("sha256")
                .update(fileBuffer)
                .digest("hex");

            validFiles++;
        }

        /**
         * No valid files
         */
        if (validFiles === 0) {

            return {
                valid: false,

                score: 0,

                reason:
                    "No valid uploaded files"
            };
        }

        /**
         * Dynamic file score
         */
        const score =
            Math.min(
                (validFiles * 25),
                100
            );

        return {
            valid: score >= 50,

            score
        };

    } catch (error) {

        console.error(error);

        return {
            valid: false,

            score: 0,

            reason:
                "Deliverable verification failed"
        };
    }
}