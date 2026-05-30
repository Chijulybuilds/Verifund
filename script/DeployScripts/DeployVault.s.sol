// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VerifundBasicVault} from "../../src/Vault.sol";
import {HelperConfigVault} from "../HelperConfigScript/HelperConfigVault.s.sol";

contract DeployVault is Script {
    /**
     * @notice Resolves the token address used by run() on the current chain/env namespace.
     * @return tokenAddress The resolved vault token address.
     */
    function resolvedTokenAddressForRun() external returns (address tokenAddress) {
        HelperConfigVault helperConfig = new HelperConfigVault();
        HelperConfigVault.VaultDeployConfig memory config = helperConfig.getActiveNetworkConfig();

        return config.tokenAddress;
    }

    /**
     * @notice Resolves the token address used by runWithEnvPrefix() for a given namespace.
     * @param envPrefix The env namespace prefix, e.g. "DEPLOY_A".
     * @return tokenAddress The resolved vault token address.
     */
    function resolvedTokenAddressForRunWithPrefix(string calldata envPrefix) external returns (address tokenAddress) {
        HelperConfigVault helperConfig = new HelperConfigVault();
        HelperConfigVault.VaultDeployConfig memory config = helperConfig.getActiveNetworkConfigWithPrefix(envPrefix);

        return config.tokenAddress;
    }

    /**
     * @notice Deploys vault using active-chain defaults and optional VAULT_* env overrides.
     * @return vault The deployed VerifundBasicVault instance.
     */
    function run() external returns (VerifundBasicVault vault) {
        HelperConfigVault helperConfig = new HelperConfigVault();
        HelperConfigVault.VaultDeployConfig memory config = helperConfig.getActiveNetworkConfig();

        return _deploy(config);
    }

    /**
     * @notice Deploys vault using a prefixed env namespace for overrides.
     * @param envPrefix The env namespace prefix, e.g. "DEPLOY_A".
     * @return vault The deployed VerifundBasicVault instance.
     */
    function runWithEnvPrefix(string calldata envPrefix) external returns (VerifundBasicVault vault) {
        HelperConfigVault helperConfig = new HelperConfigVault();
        HelperConfigVault.VaultDeployConfig memory config = helperConfig.getActiveNetworkConfigWithPrefix(envPrefix);

        return _deploy(config);
    }

    /**
     * @notice Internal vault deployment executor.
     * @param config The resolved vault deployment configuration.
     * @return vault The deployed VerifundBasicVault instance.
     */
    function _deploy(HelperConfigVault.VaultDeployConfig memory config) internal returns (VerifundBasicVault vault) {
        vm.startBroadcast();
        vault = new VerifundBasicVault(config.tokenAddress);
        vm.stopBroadcast();

        return vault;
    }
}
