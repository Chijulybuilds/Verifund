// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ERC223 Token
 * @author Prince_Chinedu
 * @dev Interface for ERC223 tokens
 */

import {Ownable} from "../lib/Token-contracts/Ownable.sol";
import {IERC223Recipient} from "../lib/Token-contracts/IERC223Recipient.sol";
import {IERC223} from "../lib/Token-contracts/IERC223.sol";

/*//////////////////////////////////////////////////////////////
                        ERC223 TOKEN
////////////////////////////////////////////////////////////*/

contract SecureERC223Token is IERC223, Ownable {
    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error UnsafeRecipient();
    error MintToZeroAddress();

    /*//////////////////////////////////////////////////////////////
                          TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    string private _tokenName;
    string private _tokenSymbol;
    uint8 private immutable _tokenDecimals;
    uint256 private _supply;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply)
        Ownable(msg.sender)
    {
        _tokenName = name_;
        _tokenSymbol = symbol_;
        _tokenDecimals = decimals_;

        _mint(msg.sender, initialSupply);
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA
    //////////////////////////////////////////////////////////////*/

    function name() external view override returns (string memory) {
        return _tokenName;
    }

    function symbol() external view override returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() external view override returns (uint8) {
        return _tokenDecimals;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC223 LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice ERC223 transfer without metadata
     */
    function transfer(address to, uint256 value) external override returns (bool) {
        bytes memory emptyData = "";

        _transfer(msg.sender, to, value, emptyData);

        return true;
    }

    /**
     * @notice ERC223 transfer with metadata
     */
    function transfer(address to, uint256 value, bytes calldata data) external override returns (bool) {
        _transfer(msg.sender, to, value, data);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         OPTIONAL ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers tokens from one address to another
     * @param spender The address alloed to spend token
     * @param amount The amount of tokens to transfer
     */

    function approve(address spender, uint256 amount) external override returns (bool) {
        if (spender == address(0)) revert ZeroAddress();

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Transfers tokens from one address to another
     * @param tokenOwner The address of the owner of the tokens
     * @param spender The address allowed to spend token
     *
     */

    function allowance(address tokenOwner, address spender) external view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    /**
     * @notice Transfers tokens from one address to another
     * @param from The address of the owner of the tokens
     * @param to The address of the recipient allowed to spend token
     * @param amount The amount of tokens to transfer
     */

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        // the current amount approved to be spent and should be greater than amount sent
        uint256 currentAllowance = _allowances[from][msg.sender];

        // checks if amount approved for the spender is sufficient
        if (currentAllowance < amount) {
            revert InsufficientAllowance();
        }

        unchecked {
            _allowances[from][msg.sender] = currentAllowance - amount;
        }

        bytes memory emptyData = "";

        _transfer(from, to, amount, emptyData);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 value, bytes memory data) internal {
        if (to == address(0)) revert ZeroAddress();

        uint256 senderBalance = _balances[from];

        if (senderBalance < value) {
            revert InsufficientBalance();
        }

        unchecked {
            _balances[from] = senderBalance - value;
        }

        _balances[to] += value;

        /**
         * IMPORTANT:
         * State changes happen BEFORE external interaction.
         * This follows CEI:
         * Checks -> Effects -> Interactions
         */
        if (_isContract(to)) {
            try IERC223Recipient(to).tokenReceived(from, value, data) {}
            catch {
                revert UnsafeRecipient();
            }
        }

        emit Transfer(from, to, value, data);
    }

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert MintToZeroAddress();

        _supply += amount;

        _balances[to] += amount;

        bytes memory emptyData = "";

        emit Transfer(address(0), to, amount, emptyData);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER MINT
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                         CONTRACT DETECTION
    //////////////////////////////////////////////////////////////*/

    // checks if the address the token is sent to is a contract
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
