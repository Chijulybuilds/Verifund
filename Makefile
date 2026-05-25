-include .env

.PHONY: test coverage debug deploy deploy_vault contract_abi verify_contract

test:
	forge test -vvv --fork-url ${SEPOLIA_URL} && forge test -vvv --fork-url ${MAINNET_URL}

coverage:
	forge coverage --fork-url ${SEPOLIA_URL} && forge coverage --fork-url ${MAINNET_URL}

debug:
	forge coverage --report debug > coverage.txt --fork-url ${SEPOLIA_URL} 

deploy:
	forge script script/DeployToken.s.sol --rpc-url ${SEPOLIA_URL} --private-key ${PRIVATE_KEY} --broadcast 

deploy_vault:
	forge script script/DeployVault.s.sol --rpc-url ${SEPOLIA_URL} --private-key ${PRIVATE_KEY_2} --broadcast

contract_abi:
	cast abi-encode "constructor(string,string,uint8,uint256)" "VeriTok" "VRT" 18 100000000000000000000000

verify_contract:
	forge verify-contract 0x5faccfd519d3177bb47c5eb57f203bca972fcdf7 src/Token.sol:SecureERC223Token \
  --chain-id 11155111 \
  --etherscan-api-key ${ETHERSCAN_API_KEY} \
  --watch \
  --constructor-args ${CONTRACT_ABI}
