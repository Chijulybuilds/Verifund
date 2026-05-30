// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {VerifundFreelanceEscrow} from "../../src/FreelanceEscrow.sol";

import {HelperConfigFreelanceEscrow} from "../HelperConfigScript/HelperConfigFreelanceEscrow.s.sol";

contract DeployFreelanceEscrow is Script {
    address private immutable freelancer = vm.envAddress("FREELANCER_ETH_ADDRESS");
    address private immutable erc223Token = vm.envAddress("ERC223_ADDRESS");

    function run() external returns (VerifundFreelanceEscrow) {
        HelperConfigFreelanceEscrow helper = new HelperConfigFreelanceEscrow();

        HelperConfigFreelanceEscrow.NetworkConfig memory config = helper.getActiveNetworkConfig();

        vm.startBroadcast();
        VerifundFreelanceEscrow escrow = new VerifundFreelanceEscrow(
            freelancer,
            erc223Token,
            VerifundFreelanceEscrow.AssetType.ERC223,
            block.timestamp + 7 days,
            config.creOracle
        );

        vm.stopBroadcast();
        return escrow;
    }
}
