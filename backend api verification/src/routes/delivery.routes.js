"use strict";
// src/routes/delivery.routes.ts
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var express_1 = __importDefault(require("express"));
var delivery_controller_1 = require("../controllers/delivery.controller");
var router = express_1.default.Router();
router.post("/submit-delivery", delivery_controller_1.submitDelivery);
exports.default = router;
