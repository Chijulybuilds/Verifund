"use strict";
// services/disputeEngine.ts
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
exports.runDisputeVerification = runDisputeVerification;
var githubVerifier_1 = require("./githubVerifier");
var urlVerifier_1 = require("./urlVerifier");
var timestampVerifier_1 = require("./timestampVerifier");
var deliverableVerifier_1 = require("./deliverableVerifier");
function runDisputeVerification(submission, checks, deadline) {
    return __awaiter(this, void 0, void 0, function () {
        var totalChecks, passedChecks, results, githubResult, deploymentResult, filesResult, deadlineResult, score, approved;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    totalChecks = 0;
                    passedChecks = 0;
                    results = {};
                    if (!(checks.github &&
                        submission.repoOwner &&
                        submission.repoUrl &&
                        submission.repobranch &&
                        submission.reposha)) return [3 /*break*/, 2];
                    totalChecks++;
                    return [4 /*yield*/, (0, githubVerifier_1.verifyGithubRepository)(submission.repoOwner, submission.repoUrl, submission.repobranch, submission.reposha)];
                case 1:
                    githubResult = _a.sent();
                    results.github = githubResult;
                    if (githubResult.valid) {
                        passedChecks++;
                    }
                    _a.label = 2;
                case 2:
                    if (!(checks.deployment &&
                        submission.deploymentUrl)) return [3 /*break*/, 4];
                    totalChecks++;
                    return [4 /*yield*/, (0, urlVerifier_1.verifyDeploymentUrl)(submission.deploymentUrl)];
                case 3:
                    deploymentResult = _a.sent();
                    results.deployment = deploymentResult;
                    if (deploymentResult.valid) {
                        passedChecks++;
                    }
                    _a.label = 4;
                case 4:
                    if (!(checks.files &&
                        submission.uploadedFiles)) return [3 /*break*/, 6];
                    totalChecks++;
                    return [4 /*yield*/, (0, deliverableVerifier_1.verifyDeliverables)(submission.uploadedFiles)];
                case 5:
                    filesResult = _a.sent();
                    results.files = filesResult;
                    if (filesResult.valid) {
                        passedChecks++;
                    }
                    _a.label = 6;
                case 6:
                    if (!checks.deadline) return [3 /*break*/, 8];
                    totalChecks++;
                    return [4 /*yield*/, (0, timestampVerifier_1.verifyDeliveryDeadline)(submission.uploadedAt, deadline)];
                case 7:
                    deadlineResult = _a.sent();
                    results.deadline = deadlineResult;
                    if (deadlineResult.valid) {
                        passedChecks++;
                    }
                    _a.label = 8;
                case 8:
                    score = totalChecks === 0
                        ? 0
                        : Math.floor((passedChecks * 100)
                            /
                                totalChecks);
                    approved = score >= 90;
                    return [2 /*return*/, {
                            approved: approved,
                            score: score,
                            totalChecks: totalChecks,
                            passedChecks: passedChecks,
                            results: results
                        }];
            }
        });
    });
}
