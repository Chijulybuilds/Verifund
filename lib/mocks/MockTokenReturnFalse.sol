// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC223} from "../Token-contracts/IERC223.sol";

contract MockTokenReturnFalse is IERC223 {
    mapping(address => uint256) private _balances;

    function name() public pure returns (string memory) {
        return "FalseToken";
    }

    function symbol() public pure returns (string memory) {
        return "FLT";
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

    function transfer(address, uint256) public pure returns (bool) {
        return false;
    }

    function transfer(address, uint256, bytes calldata) public pure returns (bool) {
        return false;
    }

    function approve(address, uint256) public pure returns (bool) {
        return true;
    }

    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }

    function transferFrom(address, address, uint256) public pure returns (bool) {
        return false;
    }
}