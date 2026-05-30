// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {NetworkConfigModule} from "../modules/NetworkConfigModule.sol";

contract HelperConfigVault is Script {
    error InvalidVaultTokenAddress(address tokenAddress);

    struct VaultDeployConfig {
        address tokenAddress;
    }

    /**
     * @notice Returns active vault config using chain defaults and optional VAULT_* env overrides.
     * @return config The resolved vault deployment configuration.
     */
    function getActiveNetworkConfig() public view returns (VaultDeployConfig memory config) {
        return getActiveNetworkConfigWithPrefix("");
    }

    /**
     * @notice Returns active vault config using chain defaults and optional prefixed env overrides.
     * @param prefix The env namespace prefix, e.g. "DEPLOY_A" for DEPLOY_A_VAULT_* keys.
     * @return config The resolved vault deployment configuration.
     */
    function getActiveNetworkConfigWithPrefix(string memory prefix)
        public
        view
        returns (VaultDeployConfig memory config)
    {
        config = getNetworkConfigByChainId(block.chainid);
        config = _applyEnvOverrides(config, prefix);
        _validateConfig(config);
    }

    /**
     * @notice Returns chain-specific base vault config (mainnet/sepolia only).
     * @param chainId The chain ID used for config resolution.
     * @return config The base vault deployment configuration.
     */
    function getNetworkConfigByChainId(uint256 chainId) public view returns (VaultDeployConfig memory config) {
        if (chainId == NetworkConfigModule.CHAIN_ID_MAINNET) {
            return VaultDeployConfig({tokenAddress: vm.envAddress("MAINNET_TOKEN_ADDRESS")});
        }

        if (chainId == NetworkConfigModule.CHAIN_ID_SEPOLIA) {
            return VaultDeployConfig({tokenAddress: vm.envAddress("SEPOLIA_TOKEN_ADDRESS")});
        }

        revert NetworkConfigModule.UnsupportedChainId(chainId);
    }

    /**
     * @notice Applies optional env overrides to the base vault config.
     * @param config The base vault config.
     * @param prefix The env namespace prefix used to read override keys.
     * @return The config after applying env overrides.
     */
    function _applyEnvOverrides(VaultDeployConfig memory config, string memory prefix)
        internal
        view
        returns (VaultDeployConfig memory)
    {
        string memory scopedPrefix = bytes(prefix).length == 0 ? "VAULT" : string.concat(prefix, "_VAULT");

        config.tokenAddress = vm.envOr(string.concat(scopedPrefix, "_TOKEN_ADDRESS"), config.tokenAddress);

        return config;
    }

    /**
     * @notice Validates vault deployment configuration.
     * @param config The vault deployment configuration to validate.
     */
    function _validateConfig(VaultDeployConfig memory config) internal view {
        if (config.tokenAddress == address(0) || config.tokenAddress.code.length == 0) {
            revert InvalidVaultTokenAddress(config.tokenAddress);
        }
    }
}
