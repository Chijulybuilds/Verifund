"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var express_1 = __importDefault(require("express"));
var disputeController_1 = require("../controllers/disputeController");
var router = express_1.default.Router();
/**
 * POST /api/dispute/verify
 */
router.post("/verify", disputeController_1.verifyDispute);
exports.default = router;
