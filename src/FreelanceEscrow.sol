// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * =============================================================================
 *                           VERIFUND ESCROW PROTOCOL
 * =============================================================================
 *
 * @title VerifundEscrow
 * @author Prince_Chinedu
 *
 * @notice
 * A production-inspired escrow protocol supporting:
 *
 * - ETH escrow
 * - ERC223 escrow
 * - delivery deadlines
 * - freelancer workflow
 * - client approval/dispute flow
 * - Chainlink Automation time-based execution
 * - automatic refunds
 * - automatic payment release
 * - pull payment architecture
 * - reentrancy protection
 *
 * =============================================================================
 * ARCHITECTURE
 * =============================================================================
 *
 * CLIENT
 *   ↓
 * Deploy Escrow
 *   ↓
 * Set:
 * - freelancer
 * - asset type
 * - deadline
 *   ↓
 * Fund Escrow
 *   ↓
 * Freelancer Delivers
 *   ↓
 * Client:
 * - approve
 * - dispute
 * - ignore
 *   ↓
 * Chainlink Automation:
 *
 * CASE 1:
 * Freelancer misses delivery deadline
 * → refund client
 *
 * CASE 2:
 * Client ignores after delivery
 * → release freelancer funds
 *
 * =============================================================================
 * IMPORTANT
 * =============================================================================
 *
 * This contract is:
 * - Chainlink Automation compatible
 * - NOT Chainlink Functions integrated yet
 *
 * Future versions can integrate:
 * - AI dispute resolution
 * - backend verification
 * - Chainlink Functions
 * - milestone escrows
 * - DAO arbitration
 *
 * =============================================================================
 */

import {IERC223} from "../lib/Token-contracts/IERC223.sol";

import {IERC223Recipient} from "../lib/Token-contracts/IERC223Recipient.sol";

import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import {IVerifierReceiver} from "./interfaces/IVerifierReceiver.sol";

/// ---------------------------------------------------------------------------
/// CUSTOM ERRORS
/// ---------------------------------------------------------------------------

error Escrow__OnlyClient();
error Escrow__OnlyFreelancer();
error Escrow__InvalidState();
error Escrow__AmountMustBeGreaterThanZero();
error Escrow__TransferFailed();
error Escrow__UnauthorizedToken();
error Escrow__NoWithdrawableBalance();
error Escrow__ReentrantCall();
error Escrow__InvalidAddress();
error Escrow__TokenMustBeContract();
error Escrow__InvalidDeadline();
error Escrow__DeadlineAlreadyPassed();
error Escrow__DecisionWindowStillActive();
error Escrow__UpkeepNotNeeded();
error Escrow__InvalidDeliveryReference();
error Escrow__InvalidDeliveryMessage();
error Escrow__OnlyOracle();
error Escrow__NoPendingDispute();
error Escrow__EvidenceAlreadyProcessed();
error Escrow__EvidenceHashMismatch();
error Escrow__InvalidOracleAddress();

/// ---------------------------------------------------------------------------
/// CONTRACT
/// ---------------------------------------------------------------------------

contract VerifundFreelanceEscrow is IERC223Recipient, AutomationCompatibleInterface, IVerifierReceiver {
    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum EscrowState {
        CREATED,
        FUNDED,
        DELIVERED,
        APPROVED,
        DISPUTED,
        RELEASED,
        REFUNDED,
        EXPIRED
    }

    enum AssetType {
        ETH,
        ERC223
    }

    enum DeliveryType {
        FILE_UPLOAD,
        GITHUB_REPO,
        WEBSITE,
        MOBILE_APP,
        MIXED
    }

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable i_client;

    address public immutable i_freelancer;

    IERC223 public immutable i_token;

    AssetType public immutable i_assetType;

    /**
     * @notice
     * Hard delivery deadline.
     *
     * If freelancer fails to deliver before this:
     * client refunded automatically.
     */
    uint256 public immutable i_deliveryDeadline;

    /**
     * @notice
     * Client decision timeout after delivery.
     */
    uint256 public constant DECISION_WINDOW = 48 hours;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    EscrowState private s_escrowState;

    /**
     * @notice
     * Escrowed asset amount.
     */
    uint256 private s_escrowAmount;
    /**
     * @notice
     * Delivery timestamp. When product is delivered
     */
    uint256 private s_deliveryTimestamp;

    /**
     * @notice
     * Pull payment balances.
     */
    mapping(address => uint256) private s_withdrawableBalances;

    /**
     * @notice
     * Reentrancy lock.
     */
    bool private s_locked;
    string private s_repoUrl;
    string private s_fileupload;
    string private s_websiteUrl;
    string private s_mobileappUrl;
    string private s_mixed;
    string private s_deliveryReference;
    string private s_deliveryMessage;

    /*//////////////////////////////////////////////////////////////
                         CRE WORKFLOW VARIABLES
    //////////////////////////////////////////////////////////////*/

    address private immutable i_creOracle;
    bool private s_disputePending;
    bytes32 private s_evidenceHash;
    mapping(bytes32 => bool) private s_processedEvidence;

    // bytes32 private s_evidenceHash;
    DeliveryType private s_deliveryType;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event EscrowFunded(address indexed client, uint256 amount);

    event WorkDelivered(
        address indexed freelancer,
        string s_deliveryMessage,
        string s_deliveryReference,
        DeliveryType,
        uint256 timestamp
    );

    event WorkApproved(address indexed client);

    event WorkDisputed(address indexed client);

    event EscrowExpired(uint256 timestamp);

    /**
     * @dev the token is relased to freelancer although still in contract
     */
    event FundsReleased(address indexed freelancer, uint256 amount);

    event FundsRefunded(address indexed client, uint256 amount);

    /**
     * @dev the token is removed from contract to freelancer's wallet by freelancer to recepient
     */
    event WithdrawalExecuted(address indexed recipient, uint256 amount);

    event DisputeVerificationRequested(address indexed client, bytes32 indexed evidenceHash, string deliveryReference);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier nonReentrant() {
        if (s_locked) {
            revert Escrow__ReentrantCall();
        }

        s_locked = true;
        _;
        s_locked = false;
    }

    modifier onlyClient() {
        if (msg.sender != i_client) {
            revert Escrow__OnlyClient();
        }

        _;
    }

    modifier onlyFreelancer() {
        if (msg.sender != i_freelancer) {
            revert Escrow__OnlyFreelancer();
        }

        _;
    }

    modifier inState(EscrowState expectedState) {
        if (s_escrowState != expectedState) {
            revert Escrow__InvalidState();
        }

        _;
    }

    modifier onlyOracle() {
        if (msg.sender != i_creOracle) {
            revert Escrow__OnlyOracle();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param freelancer freelancer receiving funds
     * @param tokenAddress ERC223 token address
     * @param assetType ETH or ERC223
     * @param deliveryDeadline timestamp freelancer must deliver before
     */
    constructor(
        address freelancer,
        address tokenAddress,
        AssetType assetType,
        uint256 deliveryDeadline,
        address creOracle
    ) {
        if (freelancer == address(0)) {
            revert Escrow__InvalidAddress();
        }

        if (deliveryDeadline <= block.timestamp) {
            revert Escrow__InvalidDeadline();
        }

        i_client = msg.sender;

        i_freelancer = freelancer;

        i_assetType = assetType;

        i_deliveryDeadline = deliveryDeadline;

        if (assetType == AssetType.ERC223) {
            if (tokenAddress == address(0)) {
                revert Escrow__InvalidAddress();
            }

            if (tokenAddress.code.length == 0) {
                revert Escrow__TokenMustBeContract();
            }

            i_token = IERC223(tokenAddress);
        }

        s_escrowState = EscrowState.CREATED;

        if (creOracle == address(0)) {
            revert Escrow__InvalidOracleAddress();
        }

        i_creOracle = creOracle;
    }

    /*//////////////////////////////////////////////////////////////
                             FUND ESCROW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Fund ETH escrow.
     */
    function fundETH() public payable onlyClient inState(EscrowState.CREATED) {
        if (i_assetType != AssetType.ETH) {
            revert Escrow__UnauthorizedToken();
        }

        if (msg.value == 0) {
            revert Escrow__AmountMustBeGreaterThanZero();
        }

        s_escrowAmount = msg.value;

        s_escrowState = EscrowState.FUNDED;

        emit EscrowFunded(msg.sender, msg.value);
    }

    /**
     * @notice
     * ERC223 funding hook.
     */
    function tokenReceived(address from, uint256 value, bytes calldata)
        external
        override
        onlyClient
        inState(EscrowState.CREATED)
    {
        if (i_assetType != AssetType.ERC223) {
            revert Escrow__UnauthorizedToken();
        }

        if (msg.sender != address(i_token)) {
            revert Escrow__UnauthorizedToken();
        }

        if (from != i_client) {
            revert Escrow__OnlyClient();
        }

        if (value == 0) {
            revert Escrow__AmountMustBeGreaterThanZero();
        }

        s_escrowAmount = value;

        s_escrowState = EscrowState.FUNDED;

        emit EscrowFunded(from, value);
    }

    /*//////////////////////////////////////////////////////////////
                           DELIVERY WORKFLOW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Freelancer marks work delivered.
     */
    function markDelivered(
        DeliveryType deliveryType,
        string calldata deliveryReference,
        string calldata deliveryMessage
        // bytes32 evidenceHash------will be implemented when frontend exists
    ) external onlyFreelancer inState(EscrowState.FUNDED) {
        /**
         * @dev Prevent late delivery.
         */
        if (block.timestamp > i_deliveryDeadline) {
            revert Escrow__DeadlineAlreadyPassed();
        }

        /**
         * @dev Ensure delivery reference exists.
         */
        if (bytes(deliveryReference).length == 0) {
            revert Escrow__InvalidDeliveryReference();
        }

        /**
         * @dev Optional delivery notes validation.
         */
        if (bytes(deliveryMessage).length == 0) {
            revert Escrow__InvalidDeliveryMessage();
        }

        /**
         * ---------------------------------------------------------
         * STORE DELIVERY METADATA
         * ---------------------------------------------------------
         */

        s_deliveryType = deliveryType;

        s_deliveryReference = deliveryReference;

        s_deliveryMessage = deliveryMessage;

        // s_evidenceHash = evidenceHash;

        s_deliveryTimestamp = block.timestamp;

        /**
         * ---------------------------------------------------------
         * STATE TRANSITION
         * ---------------------------------------------------------
         */

        s_escrowState = EscrowState.DELIVERED;

        emit WorkDelivered(msg.sender, s_deliveryMessage, s_deliveryReference, s_deliveryType, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                             PLACE OF WORK
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Client disputes work.
     *
     * FUTURE:
     * Chainlink Functions +
     * backend AI verification.
     */

    function disputeWork(bytes32 evidenceHash) external onlyClient inState(EscrowState.DELIVERED) {
        if (s_processedEvidence[evidenceHash]) {
            revert Escrow__EvidenceAlreadyProcessed();
        }

        s_escrowState = EscrowState.DISPUTED;

        s_disputePending = true;

        s_evidenceHash = evidenceHash;

        emit DisputeVerificationRequested(msg.sender, evidenceHash, s_deliveryReference);
    }

    /*//////////////////////////////////////////////////////////////
                              CRE CALLBACK
    //////////////////////////////////////////////////////////////*/

    function fulfillDisputeResolution(bool approved, bytes32 evidenceHash) external override onlyOracle {
        if (!s_disputePending) {
            revert Escrow__NoPendingDispute();
        }

        if (evidenceHash != s_evidenceHash) {
            revert Escrow__EvidenceHashMismatch();
        }
        s_processedEvidence[evidenceHash] = true;
        s_disputePending = false;

        if (approved) {
            _releaseFundsToFreelancer();
        } else {
            _refundClient();
        }
    }

    /*//////////////////////////////////////////////////////////////
                         CHAINLINK AUTOMATION
    //////////////////////////////////////////////////////////////*/

    /**
     * =============================================================================
     * checkUpkeep()
     * =============================================================================
     *
     * Chainlink nodes continuously simulate this off-chain.
     *
     * NO STATE CHANGES HERE.
     *
     * CONDITIONS:
     *
     * CASE 1:
     * Freelancer missed delivery deadline--automatic release of funds back to client
     *
     * CASE 2:
     * Freelancer ignored after delivery--automatic release of funds to freelancer
     *
     * =============================================================================
     */
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        /**
         * @dev deliveryexpiration becomes true if escrow is funded &
         * @dev delivery of service/product is greater than when contract is deployed
         */
        bool deliveryExpired = (s_escrowState == EscrowState.FUNDED && block.timestamp >= i_deliveryDeadline);

        /**
         * @dev autoReleaseNeeded to freelancer becomes TRUE if service/product has been delivered
         * @dev and the time client has to verify is higher than --
         * @dev the sum of delivery deadline and the 48 hurs decision window.
         */

        bool autoReleaseNeeded =
            (s_escrowState == EscrowState.DELIVERED && block.timestamp >= s_deliveryTimestamp + DECISION_WINDOW);

        upkeepNeeded = deliveryExpired || autoReleaseNeeded;

        performData = abi.encode(deliveryExpired, autoReleaseNeeded);
    }

    /**
     * =============================================================================
     * performUpkeep()
     * =============================================================================
     *
     * Chainlink Automation executes this on-chain.
     *
     * IMPORTANT:
     * Always revalidate conditions.
     *
     * Never trust performData blindly.
     *
     * =============================================================================
     */
    function performUpkeep(bytes calldata performData) external override {
        (bool deliveryExpired, bool autoReleaseNeeded) = abi.decode(performData, (bool, bool));

        /**
         * @dev Revalidation.
         */
        bool validDeliveryExpiration =
            (deliveryExpired && s_escrowState == EscrowState.FUNDED && block.timestamp >= i_deliveryDeadline);

        bool validAutoRelease =
            (autoReleaseNeeded && s_escrowState == EscrowState.DELIVERED
                && block.timestamp >= s_deliveryTimestamp + DECISION_WINDOW);

        if (!validDeliveryExpiration && !validAutoRelease) {
            revert Escrow__UpkeepNotNeeded();
        }

        /**
         * CASE 1:
         * Freelancer failed delivery.
         */
        if (validDeliveryExpiration) {
            s_escrowState = EscrowState.EXPIRED;

            emit EscrowExpired(block.timestamp);

            _refundClient();
        }

        /**
         * CASE 2:
         * Client ghosted after delivery.
         */
        if (validAutoRelease) {
            _releaseFundsToFreelancer();
        }
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Credit freelancer balance.
     */
    function _releaseFundsToFreelancer() internal {
        s_withdrawableBalances[i_freelancer] += s_escrowAmount;

        s_escrowState = EscrowState.RELEASED;

        emit FundsReleased(i_freelancer, s_escrowAmount);
    }

    /**
     * @notice
     * Refund client.
     */
    function _refundClient() internal {
        s_withdrawableBalances[i_client] += s_escrowAmount;

        s_escrowState = EscrowState.REFUNDED;

        emit FundsRefunded(i_client, s_escrowAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Pull-payment withdrawal
     */
    function withdraw() external nonReentrant {
        uint256 amount = s_withdrawableBalances[msg.sender];

        if (amount == 0) {
            revert Escrow__NoWithdrawableBalance();
        }

        /**
         * @dev After withdrawal, the indiviuals balance comes to zero on escrow
         */
        s_withdrawableBalances[msg.sender] = 0;

        // checks if token withdrawal is Ether.
        if (i_assetType == AssetType.ETH) {
            (bool success,) = payable(msg.sender).call{value: amount}("");

            if (!success) {
                revert Escrow__TransferFailed();
            }
        } else {
            // withdrawal of ERC233 Verifund Token
            bool success = i_token.transfer(msg.sender, amount);

            if (!success) {
                revert Escrow__TransferFailed();
            }
        }

        emit WithdrawalExecuted(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEscrowState() external view returns (EscrowState) {
        return s_escrowState;
    }

    function getEscrowAmount() external view returns (uint256) {
        return s_escrowAmount;
    }

    function getDeliveryTimestamp() external view returns (uint256) {
        return s_deliveryTimestamp;
    }

    function getWithdrawableBalance(address user) external view returns (uint256) {
        return s_withdrawableBalances[user];
    }

    function getDecisionDeadline() external view returns (uint256) {
        if (s_escrowState != EscrowState.DELIVERED) {
            return 0;
        }

        return s_deliveryTimestamp + DECISION_WINDOW;
    }

    function getDeliveryDeadline() external view returns (uint256) {
        return i_deliveryDeadline;
    }

    fallback() external payable {
        fundETH();
    }

    receive() external payable {
        fundETH();
    }
}
