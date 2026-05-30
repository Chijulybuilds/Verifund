// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVerifierReceiver {
    function fulfillDisputeResolution(bool approved, bytes32 evidenceHash) external;
}
