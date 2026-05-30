// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * =============================================================================
 *                             BASIC ERC223 VAULT
 * =============================================================================
 *
 * @title VerifundBasicVault
 * @author Verifund
 *
 * @notice
 * A beginner-friendly but security-conscious vault contract that accepts
 * ERC223 tokens.
 * =============================================================================
 */
import {IERC223} from "../lib/Token-contracts/IERC223.sol";
import {IERC223Recipient} from "../lib/Token-contracts/IERC223Recipient.sol";

/// ---------------------------------------------------------------------------
/// CUSTOM ERRORS
/// ---------------------------------------------------------------------------

error Vault__AmountMustBeGreaterThanZero();
error Vault__OnlySupportedToken();
error Vault__InsufficientShareBalance();
error Vault__TransferFailed();
error Vault__ReentrantCall();
error Vault__ZeroTokenAddress();
error Vault__TokenMustBeContract();
error Vault__ZeroSharesMinted();

/// ---------------------------------------------------------------------------
/// CONTRACT
/// ---------------------------------------------------------------------------

contract VerifundBasicVault is IERC223Recipient {
    /// -----------------------------------------------------------------------
    /// STATE VARIABLES
    /// -----------------------------------------------------------------------
    /**
     * @notice
     * The ERC223 token accepted by this vault.
     */
    IERC223 public immutable i_token;

    /**
     * @notice
     * Tracks vault share balances for each user.
     */
    mapping(address => uint256) private s_shares;

    /**
     * @notice
     * Total asset units accounted in the vault.
     */
    uint256 private s_totalAssets;

    /**
     * @notice
     * Total shares minted by the vault.
     */
    uint256 private s_totalShares;

    /**
     * @notice
     * Simple reentrancy lock.
     */
    bool private s_locked;

    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event Deposited(address indexed user, uint256 assets, uint256 shares);

    event Withdrawn(address indexed user, uint256 assets, uint256 shares);

    /// -----------------------------------------------------------------------
    /// MODIFIERS
    /// -----------------------------------------------------------------------

    modifier nonReentrant() {
        if (s_locked) {
            revert Vault__ReentrantCall();
        }

        s_locked = true;
        _;
        s_locked = false;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Vault__AmountMustBeGreaterThanZero();
        }

        _;
    }

    /// -----------------------------------------------------------------------
    /// CONSTRUCTOR
    /// -----------------------------------------------------------------------

    /**
     * @param tokenAddress The deployed ERC223 token address.
     */
    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) {
            revert Vault__ZeroTokenAddress();
        }

        if (tokenAddress.code.length == 0) {
            revert Vault__TokenMustBeContract();
        }

        i_token = IERC223(tokenAddress);
    }

    /// -----------------------------------------------------------------------
    /// ERC223 TOKEN RECEIVER
    /// -----------------------------------------------------------------------

    /**
     * @notice
     * @dev tokenreceived() runs automatically when transfer() is called
     * @param from the address of the wallet sending the supported token
     * @param value the total value of token being deposited in the vault
     */
    function tokenReceived(address from, uint256 value, bytes calldata)
        external
        override
        nonReentrant
        moreThanZero(value)
    {
        /*
         * SECURITY CHECK:
         * Only allow the configured ERC223 token
         * to trigger deposits.
         */
        if (msg.sender != address(i_token)) {
            revert Vault__OnlySupportedToken();
        }

        // EFFECTS: convert assets to shares and update accounting.
        uint256 mintedShares = convertToShares(value);
        if (mintedShares == 0) {
            revert Vault__ZeroSharesMinted();
        }

        s_shares[from] += mintedShares;
        s_totalShares += mintedShares;
        s_totalAssets += value;

        emit Deposited(from, value, mintedShares);
    }

    /// -----------------------------------------------------------------------
    /// WITHDRAW FUNCTION
    /// -----------------------------------------------------------------------

    /**
     * @notice Withdraw deposited tokens from the vault.
     * @dev the msg.sender being the address of user who deployed the contract
     * @param amount the amount to be withdrawn from vault to deployers address
     */
    function withdraw(uint256 amount) external nonReentrant moreThanZero(amount) {
        /**
         * @dev sharesToBurn variable reps the share user wants to withdraw
         * @dev userShares variable reps the share balance of the user
         */
        uint256 sharesToBurn = _convertToSharesRoundUp(amount);
        uint256 userShares = s_shares[msg.sender];

        if (userShares < sharesToBurn) {
            revert Vault__InsufficientShareBalance();
        }

        /// -------------------------------------------------------------------
        /// EFFECTS
        /// -------------------------------------------------------------------

        s_shares[msg.sender] = userShares - sharesToBurn;
        s_totalShares -= sharesToBurn;
        s_totalAssets -= amount;

        /// -------------------------------------------------------------------
        /// INTERACTIONS
        /// -------------------------------------------------------------------

        bool success = i_token.transfer(msg.sender, amount);

        if (!success) {
            revert Vault__TransferFailed();
        }

        emit Withdrawn(msg.sender, amount, sharesToBurn);
    }

    /*//////////////////////////////////////////////////////////////
                               CONVERTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Converts asset amount to shares using current vault exchange rate.
     * @param assets Asset units to convert.
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        if (assets == 0) return 0;

        if (s_totalShares == 0 || s_totalAssets == 0) {
            return assets;
        }

        return (assets * s_totalShares) / s_totalAssets;
    }

    /**
     * @notice
     * Converts share amount to assets using current vault exchange rate.
     * @param shares Share units to convert.
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        if (shares == 0) return 0;

        if (s_totalShares == 0 || s_totalAssets == 0) {
            return shares;
        }

        return (shares * s_totalAssets) / s_totalShares;
    }

    /**
     * @notice
     * Converts assets to shares rounding up (safety for withdrawals).
     * @param assets Asset units to convert.
     */
    function _convertToSharesRoundUp(uint256 assets) internal view returns (uint256) {
        if (assets == 0) return 0;

        if (s_totalShares == 0 || s_totalAssets == 0) {
            return assets;
        }

        uint256 numerator = assets * s_totalShares;
        return (numerator + s_totalAssets - 1) / s_totalAssets;
    }

    /// -----------------------------------------------------------------------
    /// GETTER FUNCTIONS
    /// -----------------------------------------------------------------------

    /**
     * @notice
     * Returns deposited balance of a user.
     */
    function getUserAssetBalance(address user) external view returns (uint256) {
        return convertToAssets(s_shares[user]);
    }

    /**
     * @notice
     * Returns share balance of a user.
     */
    function getUserSharesBalance(address user) external view returns (uint256) {
        return s_shares[user];
    }

    /**
     * @notice
     * Returns total deposits tracked by vault.
     */
    function getTotalAssetDeposits() external view returns (uint256) {
        return s_totalAssets;
    }

    /**
     * @notice
     * Returns total shares issued by vault.
     */
    function getTotalShares() external view returns (uint256) {
        return s_totalShares;
    }

    /**
     * @notice
     * Returns actual token balance held by vault.
     *
     * Useful for verifying accounting correctness.
     */
    function getVaultTokenBalance() external view returns (uint256) {
        return i_token.balanceOf(address(this));
    }
}
