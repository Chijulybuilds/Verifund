// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC223} from "../Token-contracts/IERC223.sol";
import {IERC223Recipient} from "../Token-contracts/IERC223Recipient.sol";
import {IVaultWithdraw} from "test/VaultTest.t.sol";

contract MockReentrantERC223 is IERC223 {
    mapping(address => uint256) private _balances;
    bool public reenterOnTransfer;
    bool public reentrantCallBlocked;
    address public vault;
    uint256 private constant INITIAL_SUPPLY = 1_000_000 ether;

    function setVault(address vaultAddress) public {
        vault = vaultAddress;
    }

    function setReenterOnTransfer(bool enabled) public {
        reenterOnTransfer = enabled;
    }

    function mint(address to, uint256 amount) public {
        _balances[to] += amount;
    }

    function name() public pure returns (string memory) {
        return "ReentrantToken";
    }

    function symbol() public pure returns (string memory) {
        return "RNT";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 0;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        return _transfer(msg.sender, to, value, "");
    }

    function transfer(address to, uint256 value, bytes calldata data) public returns (bool) {
        return _transfer(msg.sender, to, value, data);
    }

    function approve(address, uint256) public pure returns (bool) {
        return true;
    }

    function allowance(address, address) public pure returns (uint256) {
        return INITIAL_SUPPLY;
    }

    function transferFrom(address, address, uint256) public pure returns (bool) {
        return false;
    }

    function _transfer(address from, address to, uint256 value, bytes memory data) internal returns (bool) {
        if (_balances[from] < value) return false;

        _balances[from] -= value;
        _balances[to] += value;

        if (to.code.length > 0) {
            IERC223Recipient(to).tokenReceived(from, value, data);
        }

        if (reenterOnTransfer && vault != address(0)) {
            try IVaultWithdraw(vault).withdraw(1) {}
            catch {
                reentrantCallBlocked = true;
            }
        }

        return true;
    }
}
