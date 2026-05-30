// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfigFreelanceEscrow is Script {
    struct NetworkConfig {
        address creOracle;
        address automationRegistry;
        address linkToken;
        uint64 chainSelector;
    }

    NetworkConfig public activeNetworkConfig;

    // Chain IDs
    uint256 private constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant ETH_MAINNET_CHAIN_ID = 1;

    // sepolia properties
    address private immutable SepCreOracle = vm.envAddress("SEPOLIA_CREORACLE");
    address private immutable SepAutRegistry = vm.envAddress("SEPOLIA_AUTOMATION_REGISTRY");
    address private immutable SepLinkToken = vm.envAddress("SEPOLIA_LINK_TOKEN");
    uint64 private immutable SepChainSelector = uint64(vm.envUint("SEPOLIA_CHAIN_SELECTOR"));

    // mainnet properties
    address private immutable MainCreOracle = vm.envAddress("MAINNET_CREORACLE");
    address private immutable MainAutRegistry = vm.envAddress("MAINNET_AUTOMATION_REGISTRY");
    address private immutable MainLinkToken = vm.envAddress("MAINNET_LINK_TOKEN");
    uint64 private immutable MainChainSelector = uint64(vm.envUint("MAINNET_CHAIN_SELECTOR"));

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            // Revert or default to local Anvil config logic
            revert("Unsupported network environment");
        }
    }

    // ETH Sepolia Configuration
    function getSepoliaConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            creOracle: SepCreOracle, //ETH/USD
            automationRegistry: SepAutRegistry,
            linkToken: SepLinkToken,
            chainSelector: SepChainSelector
        });
    }

    // ETH Mainnet Configuration
    function getMainnetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            creOracle: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // ETH/USD
            automationRegistry: 0x6593c7De001fC8542bB1703532EE1E5aA0D458fD,
            linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            chainSelector: 5009297550715157269
        });
    }

    function getActiveNetworkConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
