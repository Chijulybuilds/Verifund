"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyGithubRepository = verifyGithubRepository;
// services/githubVerifier.ts
var axios_1 = __importDefault(require("axios"));
function verifyGithubRepository(owner, repo, branch, sha) {
    return __awaiter(this, void 0, void 0, function () {
        var score, failures, repoResponse, ciPassed, checksResponse, checkRuns, hasFailedTests, err_1, prsResponse, mergedPRs, err_2, commitDetails, totalChanges, filesChanged, err_3, error_1;
        var _a, _b, _c, _d;
        return __generator(this, function (_e) {
            switch (_e.label) {
                case 0:
                    _e.trys.push([0, 12, , 13]);
                    score = 0;
                    failures = [];
                    return [4 /*yield*/, axios_1.default.get("https://api.github.com/repos/".concat(owner, "/").concat(repo), { headers: { Authorization: "Bearer ".concat(process.env.GITHUB_API_TOKEN) } })];
                case 1:
                    repoResponse = _e.sent();
                    if (repoResponse.status === 200) {
                        score += 20;
                    }
                    else {
                        failures.push("Repository could not be accessed.");
                    }
                    ciPassed = false;
                    _e.label = 2;
                case 2:
                    _e.trys.push([2, 4, , 5]);
                    return [4 /*yield*/, axios_1.default.get("https://api.github.com/repos/".concat(owner, "/").concat(repo, "/commits/").concat(branch, "/check-runs"), { headers: { Authorization: "Bearer ".concat(process.env.GITHUB_API_TOKEN) } })];
                case 3:
                    checksResponse = _e.sent();
                    checkRuns = checksResponse.data.check_runs;
                    hasFailedTests = checkRuns.some(function (run) { return run.conclusion === "failure"; });
                    if (checkRuns.length > 0 && !hasFailedTests) {
                        score += 30;
                        ciPassed = true;
                    }
                    else if (hasFailedTests) {
                        failures.push("Automated CI/CD suite contains failing test builds.");
                    }
                    else {
                        score += 15; // Partial credit if no CI actions are established yet
                    }
                    return [3 /*break*/, 5];
                case 4:
                    err_1 = _e.sent();
                    failures.push("Could not recover workflow check-runs from GitHub.");
                    return [3 /*break*/, 5];
                case 5:
                    _e.trys.push([5, 7, , 8]);
                    return [4 /*yield*/, axios_1.default.get("https://api.github.com/repos/".concat(owner, "/").concat(repo, "/pulls?state=closed"), { headers: { Authorization: "Bearer ".concat(process.env.GITHUB_API_TOKEN) } })];
                case 6:
                    prsResponse = _e.sent();
                    mergedPRs = prsResponse.data.filter(function (pr) { return pr.merged_at !== null; });
                    if (mergedPRs.length > 0) {
                        score += 25;
                    }
                    else {
                        failures.push("No merged or formally reviewed Pull Requests located.");
                    }
                    return [3 /*break*/, 8];
                case 7:
                    err_2 = _e.sent();
                    failures.push("Failed pulling workflow development logs.");
                    return [3 /*break*/, 8];
                case 8:
                    _e.trys.push([8, 10, , 11]);
                    return [4 /*yield*/, axios_1.default.get("https://api.github.com/repos/".concat(owner, "/").concat(repo, "/commits/").concat(sha), { headers: { Authorization: "Bearer ".concat(process.env.GITHUB_API_TOKEN) } })];
                case 9:
                    commitDetails = _e.sent();
                    totalChanges = ((_a = commitDetails.data.stats) === null || _a === void 0 ? void 0 : _a.total) || 0;
                    filesChanged = ((_b = commitDetails.data.files) === null || _b === void 0 ? void 0 : _b.length) || 0;
                    if (totalChanges > 0 && filesChanged > 0) {
                        score += 25;
                    }
                    else {
                        failures.push("The target cryptographic commit hash contains empty file additions.");
                    }
                    return [3 /*break*/, 11];
                case 10:
                    err_3 = _e.sent();
                    failures.push("Target deployment SHA not found inside remote workspace history.");
                    return [3 /*break*/, 11];
                case 11: 
                /**
                 * =====================================================
                 * EVALUATE PASSED STATUS
                 * =====================================================
                 */
                return [2 /*return*/, {
                        valid: score >= 75, // Base threshold requirement for individual milestone safety
                        score: score,
                        reason: failures.length > 0 ? failures.join(" | ") : "All GitHub checkpoints successfully cleared."
                    }];
                case 12:
                    error_1 = _e.sent();
                    console.error(error_1);
                    return [2 /*return*/, {
                            valid: false,
                            score: 0,
                            reason: ((_d = (_c = error_1.response) === null || _c === void 0 ? void 0 : _c.data) === null || _d === void 0 ? void 0 : _d.message) || "GitHub repository verification failed completely."
                        }];
                case 13: return [2 /*return*/];
            }
        });
    });
}
