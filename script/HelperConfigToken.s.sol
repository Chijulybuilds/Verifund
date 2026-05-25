// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {NetworkConfigModule} from "./modules/NetworkConfigModule.sol";

contract HelperConfig is Script {
    error InvalidTokenDecimals(uint256 decimals);

    /**
     * @notice Returns the active network config using the default TOKEN_* env keys.
     * @return config The resolved token deployment configuration.
     */
    function getActiveNetworkConfig()
        public
        view
        returns (NetworkConfigModule.TokenDeployConfig memory config)
    {
        return getActiveNetworkConfigWithPrefix("");
    }

    /**
     * @notice Returns the active network config using an env-prefix namespace.
     * @param prefix The env namespace prefix, e.g. "DEPLOY_A" for DEPLOY_A_TOKEN_* keys.
     * @return config The resolved token deployment configuration.
     */
    function getActiveNetworkConfigWithPrefix(string memory prefix)
        public
        view
        returns (NetworkConfigModule.TokenDeployConfig memory config)
    {
        config = getNetworkConfigByChainId(block.chainid);
        config = _applyEnvOverrides(config, prefix);
    }

    /**
     * @notice Returns default config for a specific chain ID.
     * @param chainId The chain ID used for network config resolution.
     * @return The default config for the chain.
     */
    function getNetworkConfigByChainId(uint256 chainId)
        public
        pure
        returns (NetworkConfigModule.TokenDeployConfig memory)
    {
        return NetworkConfigModule.defaultConfig(chainId);
    }

    /**
     * @notice Applies optional env overrides to a base config.
     * @param config The base network config before env overrides.
     * @param prefix The env namespace prefix to read override keys from.
     * @return The config after applying env overrides.
     */
    function _applyEnvOverrides(
        NetworkConfigModule.TokenDeployConfig memory config,
        string memory prefix
    )
        internal
        view
        returns (NetworkConfigModule.TokenDeployConfig memory)
    {
        string memory scopedPrefix = bytes(prefix).length == 0
            ? "TOKEN"
            : string.concat(prefix, "_TOKEN");

        config.name = vm.envOr(
            string.concat(scopedPrefix, "_NAME"),
            
            config.name
        );
        config.symbol = vm.envOr(
            string.concat(scopedPrefix, "_SYMBOL"),
            config.symbol
        );
        config.initialSupply = vm.envOr(
            string.concat(scopedPrefix, "_INITIAL_SUPPLY"),
            config.initialSupply
        );

        uint256 decimalsOverride = vm.envOr(
            string.concat(scopedPrefix, "_DECIMALS"),
            uint256(config.decimals)
        );
        if (decimalsOverride > type(uint8).max) {
            revert InvalidTokenDecimals(decimalsOverride);
        }
        config.decimals = uint8(decimalsOverride);

        return config;
    }
}
