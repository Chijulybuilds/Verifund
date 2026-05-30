// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title    Deployment of Token contract
 * @author   Prince Chinedu
 * @notice   This script deploys the SecureERC223Token contract.
 * @dev      Uses HelperConfig for chain defaults and optional .env overrides.
 */

import {Script} from "forge-std/Script.sol";
import {SecureERC223Token} from "../../src/Token.sol";
import {HelperConfig} from "../HelperConfigScript/HelperConfigToken.s.sol";
import {NetworkConfigModule} from "../modules/NetworkConfigModule.sol";

contract DeployToken is Script {
    /**
     * @notice Deploys token using active-chain defaults and TOKEN_* env overrides.
     * @return token The deployed SecureERC223Token instance.
     */
    function run() external returns (SecureERC223Token token) {
        HelperConfig helperConfig = new HelperConfig();
        NetworkConfigModule.TokenDeployConfig memory config = helperConfig.getActiveNetworkConfig();

        return _deploy(config);
    }

    /**
     * @notice Deploys token using an env-prefix namespace for overrides.
     * @param envPrefix The env namespace prefix, e.g. "DEPLOY_A".
     * @return token The deployed SecureERC223Token instance.
     */
    function runWithEnvPrefix(string calldata envPrefix) external returns (SecureERC223Token token) {
        HelperConfig helperConfig = new HelperConfig();
        NetworkConfigModule.TokenDeployConfig memory config = helperConfig.getActiveNetworkConfigWithPrefix(envPrefix);

        return _deploy(config);
    }

    /**
     * @notice Internal deployment executor.
     * @param config The fully resolved token deployment configuration.
     * @return token The deployed SecureERC223Token instance.
     */
    function _deploy(NetworkConfigModule.TokenDeployConfig memory config) internal returns (SecureERC223Token token) {
        vm.startBroadcast();
        token = new SecureERC223Token(config.name, config.symbol, config.decimals, config.initialSupply);
        vm.stopBroadcast();

        return token;
    }
}
