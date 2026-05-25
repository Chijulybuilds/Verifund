// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {SecureERC223Token} from "../src/Token.sol";
import {IERC223Recipient} from "../lib/Token-contracts/IERC223Recipient.sol";
import {Ownable} from "../lib/Token-contracts/Ownable.sol";
import {DeployToken} from "../script/DeployToken.s.sol";
import {HelperConfig} from "../script/HelperConfigToken.s.sol";
import {NetworkConfigModule} from "../script/modules/NetworkConfigModule.sol";

contract GoodRecipient is IERC223Recipient {
    address public lastFrom;
    uint256 public lastValue;
    bytes public lastData;
    uint256 public totalCalls;

    /**
     * @notice Accepts ERC223 transfers and records callback data.
     * @param _from The original transfer sender.
     * @param _value The token amount transferred.
     * @param _data Arbitrary transfer payload.
     */

    function tokenReceived(
        address _from,
        uint256 _value,
        bytes calldata _data
    ) public override {
        lastFrom = _from;
        lastValue = _value;
        lastData = _data;
        totalCalls++;
    }
}

contract RevertingRecipient is IERC223Recipient {

    /**
     * @notice Always reverts to simulate an unsafe recipient.
     * @param _from The original transfer sender (unused).
     * @param _value The token amount transferred (unused).
     * @param _data The transfer payload (unused).
     */

    function tokenReceived(
        address _from,
        uint256 _value,
        bytes calldata _data
    ) public pure override {
        _from;
        _value;
        _data;
        revert("reject");
    }
}

contract NonRecipient {}

contract TokenTest is Test {
    SecureERC223Token internal token;
    HelperConfig internal helperConfig;

    address internal alice;
    address internal bob;
    address internal charlie;

    string internal constant DEFAULT_NAME = "SecureERC223";
    string internal constant DEFAULT_SYMBOL = "S223";
    uint8 internal constant DEFAULT_DECIMALS = 18;
    uint256 internal constant DEFAULT_SUPPLY = 1_000_000 ether;
    uint256 internal constant MAINNET_ID = 1;
    uint256 internal constant SEPOLIA_ID = 11155111;

    /**
     * @notice Initializes test contracts and deterministic EOA-like addresses.
     */
    function setUp() public {

        /** 
        * @dev creates unique addresses to the individuals
         */
        alice = vm.addr(11);
        bob = vm.addr(12);
        charlie = vm.addr(13);

        /** 
        * @dev checks if the addresses are already deployed with code 
            and if yes will be reset to an empty code by the vm.etch
         */
        if (alice.code.length != 0) vm.etch(alice, hex"");
        if (bob.code.length != 0) vm.etch(bob, hex"");
        if (charlie.code.length != 0) vm.etch(charlie, hex"");

        /** 
        * @dev deploys a new secure ERC223 token                                                                                                                                                                                                                                                                                            
         */
        token = new SecureERC223Token(
            DEFAULT_NAME,
            DEFAULT_SYMBOL,
            DEFAULT_DECIMALS,
            DEFAULT_SUPPLY
        );
        helperConfig = new HelperConfig();
    }

    /*//////////////////////////////////////////////////////////////
                      TESTING CONTRACT CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates constructor metadata and initial mint behavior.
     */
    function testConstructorStoresMetadataAndMintsSupply() public view {
        assertEq(token.name(), DEFAULT_NAME);
        assertEq(token.symbol(), DEFAULT_SYMBOL);
        assertEq(token.decimals(), DEFAULT_DECIMALS);
        assertEq(token.totalSupply(), DEFAULT_SUPPLY);
        assertEq(token.balanceOf(address(this)), DEFAULT_SUPPLY);
    }

    
    /**
     * @notice Fuzzes constructor inputs for storage integrity.
     * @param name_ Fuzzed token name.
     * @param symbol_ Fuzzed token symbol.
     * @param decimals_ Fuzzed decimals value.
     * @param supply_ Fuzzed initial supply.
     */
    function testFuzzConstructorAcceptsAnyParams(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply_
    ) public {
        SecureERC223Token t = new SecureERC223Token(
            name_,
            symbol_,
            decimals_,
            supply_
        );

        assertEq(t.name(), name_);
        assertEq(t.symbol(), symbol_);
        assertEq(t.decimals(), decimals_);
        assertEq(t.totalSupply(), supply_);
        assertEq(t.balanceOf(address(this)), supply_);
    }

    /*//////////////////////////////////////////////////////////////
                         TESTING TOKEN TRANSFER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzzes successful transfers to EOA-like recipients.
     * @param amount Fuzzed transfer amount.
     */
    function testFuzzTransferEOAWithoutData(uint256 amount) public {
        amount = bound(amount, 0, DEFAULT_SUPPLY);

        uint256 senderBefore = token.balanceOf(address(this));
        uint256 receiverBefore = token.balanceOf(alice);

        bool ok = token.transfer(alice, amount);
        assertTrue(ok);
        assertEq(token.balanceOf(address(this)), senderBefore - amount);
        assertEq(token.balanceOf(alice), receiverBefore + amount);
    }

    /**
     * @notice Fuzzes ERC223 transfer callback path to compatible contracts.
     * @param amount Fuzzed transfer amount.
     * @param data Fuzzed transfer metadata.
     */
    function testFuzzTransferWithDataToRecipient(
        uint256 amount,
        bytes memory data
    ) public {
        amount = bound(amount, 0, DEFAULT_SUPPLY);
        GoodRecipient recipient = new GoodRecipient();

        uint256 senderBefore = token.balanceOf(address(this));

        bool ok = token.transfer(address(recipient), amount, data);
        assertTrue(ok);

        assertEq(token.balanceOf(address(this)), senderBefore - amount);
        assertEq(token.balanceOf(address(recipient)), amount);
        assertEq(recipient.lastFrom(), address(this));
        assertEq(recipient.lastValue(), amount);
        assertEq(recipient.lastData(), data);
        assertEq(recipient.totalCalls(), 1);
    }

    /**
     * @notice Verifies transfer reverts when recipient is zero address.
     * @param amount Fuzzed transfer amount.
     */
    function testFuzzTransferToZeroAddressReverts(uint256 amount) public {
        vm.expectRevert(SecureERC223Token.ZeroAddress.selector);
        token.transfer(address(0), amount);
    }

    /**
     * @notice Verifies transfer reverts for insufficient sender balance.
     * @param amount Fuzzed transfer amount.
     */
    function testFuzzTransferInsufficientBalanceReverts(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);
        vm.prank(alice);
        vm.expectRevert(SecureERC223Token.InsufficientBalance.selector);
        token.transfer(bob, amount);
    }

    /**
     * @notice Verifies non-ERC223 contracts are rejected as recipients.
     */
    function testTransferToNonRecipientContractRevertsUnsafeRecipient() public {
        NonRecipient recipient = new NonRecipient();
        vm.expectRevert(SecureERC223Token.UnsafeRecipient.selector);
        token.transfer(address(recipient), 1 ether);
    }

    /**
     * @notice Verifies reverting recipient callbacks bubble as UnsafeRecipient.
     */
    function testTransferToRevertingContractRevertsUnsafeRecipient() public {
        RevertingRecipient recipient = new RevertingRecipient();
        vm.expectRevert(SecureERC223Token.UnsafeRecipient.selector);
        token.transfer(address(recipient), 1 ether);
    }

     /*//////////////////////////////////////////////////////////////
                      TESTING TOKEN OWNER APPROVAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzzes approve flow and allowance state.
     * @param spender Fuzzed spender address.
     * @param amount Fuzzed approved amount.
     */
    function testFuzzApproveSetsAllowance(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        bool ok = token.approve(spender, amount);
        assertTrue(ok);

        /** @dev maps from the contract address to the approved 
            spender's address which maps to the approved amount 
        */
        assertEq(token.allowance(address(this), spender), amount);
    }

    /**
     * @notice Verifies approve reverts for zero spender.
     */
    function testApproveZeroAddressReverts() public {
        vm.expectRevert(SecureERC223Token.ZeroAddress.selector);
        token.approve(address(0), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        TESTING TOKEN TRANSFERFROM OWNER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzzes successful transferFrom path with exact allowance usage.
     * @param amount Fuzzed transfer amount.
     */
    function testFuzzTransferFromSuccess(uint256 amount) public {
        amount = bound(amount, 0, DEFAULT_SUPPLY);

        token.transfer(alice, amount);

        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        bool ok = token.transferFrom(alice, charlie, amount);
        assertTrue(ok);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(charlie), amount);
        assertEq(token.allowance(alice, bob), 0);
    }

    /**
     * @notice Fuzzes insufficient-allowance path for transferFrom.
     * @param amount Fuzzed transfer amount.
     */
    function testFuzzTransferFromInsufficientAllowanceReverts(uint256 amount) public {
        amount = bound(amount, 1, DEFAULT_SUPPLY);

        token.transfer(alice, amount);
        vm.prank(bob);
        vm.expectRevert(SecureERC223Token.InsufficientAllowance.selector);
        token.transferFrom(alice, charlie, amount);
    }

    /**
     * @notice Verifies failed transferFrom keeps allowance unchanged.
     */
    function testTransferFromInsufficientBalanceRevertsAndAllowanceRollsBack(uint256 amount) public {
        amount = bound(amount, 1, 15000 ether);
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectRevert(SecureERC223Token.InsufficientBalance.selector);
        token.transferFrom(alice, charlie, amount);

        assertEq(token.allowance(alice, bob), amount);
    }

    /*//////////////////////////////////////////////////////////////
                         TESTING TOKEN MINTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fuzzes onlyOwner enforcement for mint.
     * @param amount Fuzzed mint amount.
     */
    function testFuzzMintOnlyOwner(uint256 amount) public {
        vm.prank(alice);
        vm.expectRevert(Ownable.NotOwner.selector);
        token.mint(bob, amount);
    }

    /**
     * @notice Verifies mint reverts for zero recipient.
     */
    function testMintToZeroAddressReverts() public {
        vm.expectRevert(SecureERC223Token.MintToZeroAddress.selector);
        token.mint(address(0), 1);
    }

    /**
     * @notice Fuzzes mint accounting invariants.
     * @param amount Fuzzed mint amount.
     */
    function testFuzzMintIncreasesSupplyAndReceiverBalance(uint256 amount) public {
        uint256 supplyBefore = token.totalSupply();
        uint256 receiverBefore = token.balanceOf(alice);
        amount = bound(amount, 0, type(uint256).max - supplyBefore);

        token.mint(alice, amount);

        assertEq(token.totalSupply(), supplyBefore + amount);
        assertEq(token.balanceOf(alice), receiverBefore + amount);
    }

    /*//////////////////////////////////////////////////////////////
                        TESTING NETWORK CONFIGS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies mainnet default deployment config.
     */

    function testHelperConfigMainnetDefaults() public view {
        NetworkConfigModule.TokenDeployConfig memory cfg = helperConfig
            .getNetworkConfigByChainId(MAINNET_ID);

        assertEq(cfg.name, "VeriTok Era");
        assertEq(cfg.symbol, "VRT_E");
        assertEq(cfg.decimals, 18);
        assertEq(cfg.initialSupply, 1_000_000 ether);
    }

    /**
     * @notice Verifies Sepolia default deployment config.
     */
    function testHelperConfigSepoliaDefaults() public view {
        NetworkConfigModule.TokenDeployConfig memory cfg = helperConfig
            .getNetworkConfigByChainId(SEPOLIA_ID);

        assertEq(cfg.name, "VeriTok");
        assertEq(cfg.symbol, "VRT");
        assertEq(cfg.decimals, 18);
        assertEq(cfg.initialSupply, 1_000_000 ether);
    }

    /**
     * @notice Verifies unsupported chains revert with explicit error.
     */
    function testHelperConfigUnsupportedChainReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(NetworkConfigModule.UnsupportedChainId.selector, 31337)
        );
        helperConfig.getNetworkConfigByChainId(31337);
    }

    /**
     * @notice Verifies env overrides on a supported chain using prefixed keys.
     */
    function testHelperConfigGetActiveConfigWithEnvOverrides() public {
        vm.chainId(MAINNET_ID);
        vm.setEnv("CFG_A_TOKEN_NAME", "FuzzToken");
        vm.setEnv("CFG_A_TOKEN_SYMBOL", "FZTK");
        vm.setEnv("CFG_A_TOKEN_DECIMALS", "9");
        vm.setEnv("CFG_A_TOKEN_INITIAL_SUPPLY", "4200000000");

        NetworkConfigModule.TokenDeployConfig memory cfg = helperConfig
            .getActiveNetworkConfigWithPrefix("CFG_A");

        assertEq(cfg.name, "FuzzToken");
        assertEq(cfg.symbol, "FZTK");
        assertEq(cfg.decimals, 9);
        assertEq(cfg.initialSupply, 4_200_000_000);
    }

    /**
     * @notice Verifies decimals override input is range-checked.
     */
    function testHelperConfigInvalidDecimalsReverts() public {
        vm.chainId(SEPOLIA_ID);
        vm.setEnv("CFG_B_TOKEN_DECIMALS", "256");
        vm.expectRevert(
            abi.encodeWithSelector(HelperConfig.InvalidTokenDecimals.selector, 256)
        );
        helperConfig.getActiveNetworkConfigWithPrefix("CFG_B");
    }

    /*//////////////////////////////////////////////////////////////
                         TESTING NETWORK MODULE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies deploy script uses prefixed env overrides on Sepolia.
     */
    function testDeployTokenRunDeploysTokenUsingEnvConfig() public {
        vm.chainId(SEPOLIA_ID);
        vm.setEnv("DEPLOY_A_TOKEN_NAME", "ScriptToken");
        vm.setEnv("DEPLOY_A_TOKEN_SYMBOL", "SCP");
        vm.setEnv("DEPLOY_A_TOKEN_DECIMALS", "6");
        vm.setEnv("DEPLOY_A_TOKEN_INITIAL_SUPPLY", "123456789");

        DeployToken deployScript = new DeployToken();
        SecureERC223Token deployed = deployScript.runWithEnvPrefix("DEPLOY_A");

        assertEq(deployed.name(), "ScriptToken");
        assertEq(deployed.symbol(), "SCP");
        assertEq(deployed.decimals(), 6);
        assertEq(deployed.totalSupply(), 123_456_789);
        assertEq(deployed.balanceOf(deployed.owner()), 123_456_789);
    }

    /**
     * @notice Verifies deploy script run() uses default TOKEN_* env namespace.
     */
    function testDeployTokenRunDeploysTokenUsingDefaultNamespace() public {
        vm.chainId(MAINNET_ID);
        vm.setEnv("TOKEN_NAME", "RunToken");
        vm.setEnv("TOKEN_SYMBOL", "RUN");
        vm.setEnv("TOKEN_DECIMALS", "12");
        vm.setEnv("TOKEN_INITIAL_SUPPLY", "5000000000000");

        DeployToken deployScript = new DeployToken();
        SecureERC223Token deployed = deployScript.run();

        assertEq(deployed.name(), "RunToken");
        assertEq(deployed.symbol(), "RUN");
        assertEq(deployed.decimals(), 12);
        assertEq(deployed.totalSupply(), 5_000_000_000_000);
        assertEq(deployed.balanceOf(deployed.owner()), 5_000_000_000_000);
    }
}
