// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library NetworkConfigModule {
    error UnsupportedChainId(uint256 chainId);

    uint256 internal constant CHAIN_ID_MAINNET = 1;
    uint256 internal constant CHAIN_ID_SEPOLIA = 11155111;

    struct TokenDeployConfig {
        string name;
        string symbol;
        uint8 decimals;
        uint256 initialSupply;
    }

    /**
     * @notice Returns the token deployment defaults for supported networks.
     * @param chainId The EVM chain ID to resolve config for.
     * @return config The token deployment configuration for the chain.
     */
    function defaultConfig(uint256 chainId) internal pure returns (TokenDeployConfig memory config) {
        if (chainId == CHAIN_ID_MAINNET) {
            return
                TokenDeployConfig({name: "VeriTok Era", symbol: "VRT_E", decimals: 18, initialSupply: 1_000_000 ether});
        }

        if (chainId == CHAIN_ID_SEPOLIA) {
            return TokenDeployConfig({name: "VeriTok", symbol: "VRT", decimals: 18, initialSupply: 1_000_000 ether});
        }

        revert UnsupportedChainId(chainId);
    }
}
