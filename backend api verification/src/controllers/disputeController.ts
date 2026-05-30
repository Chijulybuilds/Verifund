// controllers/disputeController.ts

import { Request, Response } from "express";

import { runDisputeVerification } from "../services/disputeEngine";

import {
    DeliverySubmission,
    DeliveryType
} from "../types/delivery.types";

import {
    VerificationChecks
} from "../types/verification.types";

export async function verifyDispute(
    req: Request,
    res: Response
) {

    try {

        /**
         * =====================================================
         * DELIVERY SUBMISSION
         * =====================================================
         */

        const submission =
            req.body as DeliverySubmission;

        /**
         * =====================================================
         * ESCROW DEADLINE
         * =====================================================
         *
         * Later:
         * fetch from DB or blockchain
         */

        const deadline =
            Number(req.body.deadline);

        /**
         * =====================================================
         * DETERMINE REQUIRED CHECKS
         * =====================================================
         */

        let checks: VerificationChecks = {};

        switch (submission.deliveryType) {

            case DeliveryType.GITHUB_REPO:

                checks = {
                    github: true,
                    deadline: true
                };

                break;

            case DeliveryType.WEBSITE:

                checks = {
                    deployment: true,
                    deadline: true
                };

                break;

            case DeliveryType.FILE_UPLOAD:

                checks = {
                    files: true,
                    deadline: true
                };

                break;

            case DeliveryType.MOBILE_APP:

                checks = {
                    github: true,
                    files: true,
                    deadline: true
                };

                break;

            case DeliveryType.MIXED:

                checks = {
                    github: true,
                    deployment: true,
                    files: true,
                    deadline: true
                };

                break;

            default:

                checks = {
                    deadline: true
                };
        }

        /**
         * =====================================================
         * RUN VERIFICATION ENGINE
         * =====================================================
         */

        const result =
            await runDisputeVerification(
                submission,
                checks,
                deadline
            );

        return res.status(200).json(result);

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false,
            error: "Dispute verification failed"
        });
    }
}