import express from "express";

import {
    verifyDispute
} from "../controllers/disputeController";

const router = express.Router();

/**
 * POST /api/dispute/verify
 */
router.post(
    "/verify",
    verifyDispute
);

export default router;