// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC223Recipient} from "../Token-contracts/IERC223Recipient.sol";


contract MockRecipientRecorder is IERC223Recipient {
    address public lastFrom;
    uint256 public lastValue;
    bytes public lastData;
    uint256 public callbackCount;

    function tokenReceived(
        address _from,
        uint256 _value,
        bytes calldata _data
    ) external override {
        lastFrom = _from;
        lastValue = _value;
        lastData = _data;
        callbackCount++;
    }
}