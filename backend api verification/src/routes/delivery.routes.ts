// src/routes/delivery.routes.ts

import express from "express";

import {
    submitDelivery
} from "../controllers/delivery.controller";

const router = express.Router();

router.post(
    "/submit-delivery",
    submitDelivery
);

export default router;