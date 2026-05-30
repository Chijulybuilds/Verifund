"use strict";
// controllers/disputeController.ts
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyDispute = verifyDispute;
var disputeEngine_1 = require("../services/disputeEngine");
var delivery_types_1 = require("../types/delivery.types");
function verifyDispute(req, res) {
    return __awaiter(this, void 0, void 0, function () {
        var submission, deadline, checks, result, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    submission = req.body;
                    deadline = Number(req.body.deadline);
                    checks = {};
                    switch (submission.deliveryType) {
                        case delivery_types_1.DeliveryType.GITHUB_REPO:
                            checks = {
                                github: true,
                                deadline: true
                            };
                            break;
                        case delivery_types_1.DeliveryType.WEBSITE:
                            checks = {
                                deployment: true,
                                deadline: true
                            };
                            break;
                        case delivery_types_1.DeliveryType.FILE_UPLOAD:
                            checks = {
                                files: true,
                                deadline: true
                            };
                            break;
                        case delivery_types_1.DeliveryType.MOBILE_APP:
                            checks = {
                                github: true,
                                files: true,
                                deadline: true
                            };
                            break;
                        case delivery_types_1.DeliveryType.MIXED:
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
                    return [4 /*yield*/, (0, disputeEngine_1.runDisputeVerification)(submission, checks, deadline)];
                case 1:
                    result = _a.sent();
                    return [2 /*return*/, res.status(200).json(result)];
                case 2:
                    error_1 = _a.sent();
                    console.error(error_1);
                    return [2 /*return*/, res.status(500).json({
                            success: false,
                            error: "Dispute verification failed"
                        })];
                case 3: return [2 /*return*/];
            }
        });
    });
}
