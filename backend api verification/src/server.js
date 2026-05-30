"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var express_1 = __importDefault(require("express"));
var cors_1 = __importDefault(require("cors"));
var helmet_1 = __importDefault(require("helmet"));
var dotenv_1 = __importDefault(require("dotenv"));
var delivery_routes_1 = __importDefault(require("./routes/delivery.routes"));
var verifyDispute_1 = __importDefault(require("./routes/verifyDispute"));
dotenv_1.default.config();
var app = (0, express_1.default)();
app.use(express_1.default.json());
app.use((0, cors_1.default)());
app.use((0, helmet_1.default)());
/**
 * ROUTES
 */
app.use("/api/delivery", delivery_routes_1.default);
app.use("/api/dispute", verifyDispute_1.default);
var PORT = process.env.PORT || 3000;
app.listen(PORT, function () {
    console.log("Server running on port ".concat(PORT));
});
