// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Vault Test
 * @author Prince_Chinedu
 */

import {Test} from "forge-std/Test.sol";
import {
    VerifundBasicVault,
    Vault__AmountMustBeGreaterThanZero,
    Vault__OnlySupportedToken,
    Vault__InsufficientShareBalance,
    Vault__TransferFailed,
    Vault__ReentrantCall,
    Vault__ZeroTokenAddress,
    Vault__TokenMustBeContract
} from "../src/Vault.sol";
import {SecureERC223Token} from "../src/Token.sol";
import {IERC223} from "../lib/Token-contracts/IERC223.sol";
import {IERC223Recipient} from "../lib/Token-contracts/IERC223Recipient.sol";
import {HelperConfigVault} from "../script/HelperConfigScript/HelperConfigVault.s.sol";
import {DeployVault} from "../script/DeployScripts/DeployVault.s.sol";
import {NetworkConfigModule} from "../script/modules/NetworkConfigModule.sol";
import {MockTokenReturnFalse} from "../lib/mocks/MockTokenReturnFalse.sol";
import {MockReentrantERC223} from "../lib/mocks/MockReentrantERC223.sol";
import {MockRecipientRecorder} from "../lib/mocks/MockRecipientRecorder.sol";

interface IVaultWithdraw {
    function withdraw(uint256 amount) external;
}

contract VaultTest is Test {
    SecureERC223Token internal token;
    VerifundBasicVault internal vault;
    HelperConfigVault internal helperConfigVault;

    address internal alice;
    address internal bob;
    address internal attacker;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        alice = vm.addr(21);
        bob = vm.addr(22);
        attacker = vm.addr(23);

        // On forked networks, deterministic addresses may already have code.
        // Force clean EOAs for stable cross-network fuzz behavior.
        if (alice.code.length != 0) vm.etch(alice, hex"");
        if (bob.code.length != 0) vm.etch(bob, hex"");
        if (attacker.code.length != 0) vm.etch(attacker, hex"");

        token = new SecureERC223Token("VaultToken", "VLT", 18, INITIAL_SUPPLY);
        vault = new VerifundBasicVault(address(token));
        helperConfigVault = new HelperConfigVault();
    }

    /*//////////////////////////////////////////////////////////////
                       TESTING VAULT CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function testConstructorRevertsOnZeroAddress() external {
        vm.expectRevert(Vault__ZeroTokenAddress.selector);
        new VerifundBasicVault(address(0));
    }

    function testConstructorRevertsWhenTokenIsNotContract(address maybeEoa) external {
        vm.assume(maybeEoa != address(0));
        vm.assume(maybeEoa.code.length == 0);

        vm.expectRevert(Vault__TokenMustBeContract.selector);
        new VerifundBasicVault(maybeEoa);
    }

    /*//////////////////////////////////////////////////////////////
                      TESTING VAULT TOKENRECEIVED
    //////////////////////////////////////////////////////////////*/

    function testTokenReceivedRevertsForUnsupportedToken() external {
        vm.prank(attacker);
        vm.expectRevert(Vault__OnlySupportedToken.selector);
        vault.tokenReceived(alice, 1 ether, "");
    }

    function testTokenReceivedRevertsForZeroAmount() external {
        vm.prank(address(token));
        vm.expectRevert(Vault__AmountMustBeGreaterThanZero.selector);
        vault.tokenReceived(alice, 0, "");
    }

    function testFuzzDepositAccounting(uint256 amount) external {
        amount = bound(amount, 1, INITIAL_SUPPLY);
        token.transfer(alice, amount);

        vm.prank(alice);
        bool success = token.transfer(address(vault), amount);
        assertTrue(success);

        assertEq(vault.getUserAssetBalance(alice), amount);
        assertEq(vault.getUserSharesBalance(alice), amount);
        assertEq(vault.getTotalAssetDeposits(), amount);
        assertEq(vault.getTotalShares(), amount);
        assertEq(vault.getVaultTokenBalance(), amount);
        assertEq(vault.convertToShares(amount), amount);
        assertEq(vault.convertToAssets(amount), amount);
    }

    /*//////////////////////////////////////////////////////////////
                         TESTING VAULT WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testFuzzWithdrawAccounting(uint256 depositAmount, uint256 withdrawAmount) external {
        depositAmount = bound(depositAmount, 1, INITIAL_SUPPLY);
        token.transfer(alice, depositAmount);

        vm.prank(alice);
        token.transfer(address(vault), depositAmount);

        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        vm.prank(alice);
        vault.withdraw(withdrawAmount);

        assertEq(vault.getUserAssetBalance(alice), depositAmount - withdrawAmount);
        assertEq(vault.getUserSharesBalance(alice), depositAmount - withdrawAmount);
        assertEq(vault.getTotalAssetDeposits(), depositAmount - withdrawAmount);
        assertEq(vault.getTotalShares(), depositAmount - withdrawAmount);
        assertEq(vault.getVaultTokenBalance(), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(alice), withdrawAmount);
    }

    function testConvertFunctionsReturnZeroForZeroInput() external {
        assertEq(vault.convertToShares(0), 0);
        assertEq(vault.convertToAssets(0), 0);
    }

    function testWithdrawRevertsForZeroAmount() external {
        vm.prank(alice);
        vm.expectRevert(Vault__AmountMustBeGreaterThanZero.selector);
        vault.withdraw(0);
    }

    function testFuzzWithdrawRevertsForInsufficientShareBalance(uint256 amount) external {
        amount = bound(amount, 1, type(uint128).max);
        vm.prank(alice);
        vm.expectRevert(Vault__InsufficientShareBalance.selector);
        vault.withdraw(amount);
    }

    /*//////////////////////////////////////////////////////////////
                        TESTING MOCKTOKENTRANSFER
    //////////////////////////////////////////////////////////////*/
    function testWithdrawRevertsWhenTokenTransferReturnsFalse() external {
        MockTokenReturnFalse falseToken = new MockTokenReturnFalse();
        VerifundBasicVault falseVault = new VerifundBasicVault(address(falseToken));

        vm.prank(address(falseToken));
        falseVault.tokenReceived(alice, 10 ether, "");

        vm.prank(alice);
        vm.expectRevert(Vault__TransferFailed.selector);
        falseVault.withdraw(1 ether);
    }

    function testMockTokenReturnFalseMetadataAndStateViews() external {
        MockTokenReturnFalse falseToken = new MockTokenReturnFalse();

        assertEq(falseToken.name(), "FalseToken");
        assertEq(falseToken.symbol(), "FLT");
        assertEq(falseToken.decimals(), 18);
        assertEq(falseToken.totalSupply(), 0);
        assertEq(falseToken.balanceOf(alice), 0);
        assertEq(falseToken.balanceOf(address(this)), 0);
    }

    function testFuzzMockTokenReturnFalseInterfaceCalls(
        address owner,
        address spender,
        address to,
        uint256 amount,
        bytes memory data
    ) external {
        vm.assume(data.length <= 128);

        MockTokenReturnFalse falseToken = new MockTokenReturnFalse();

        bool transferNoData = falseToken.transfer(to, amount);
        bool transferWithData = falseToken.transfer(to, amount, data);
        bool approved = falseToken.approve(spender, amount);
        uint256 allowed = falseToken.allowance(owner, spender);
        bool transferFromOk = falseToken.transferFrom(owner, to, amount);

        assertFalse(transferNoData);
        assertFalse(transferWithData);
        assertTrue(approved);
        assertEq(allowed, 0);
        assertFalse(transferFromOk);
        assertEq(falseToken.balanceOf(owner), 0);
    }

    /*//////////////////////////////////////////////////////////////
                       TESTING MOCKREENTRANTERC223
    //////////////////////////////////////////////////////////////*/

    function testMockReentrantERC223MetadataAndStateViews() external {
        MockReentrantERC223 reentrantToken = new MockReentrantERC223();

        assertEq(reentrantToken.name(), "ReentrantToken");
        assertEq(reentrantToken.symbol(), "RNT");
        assertEq(reentrantToken.decimals(), 18);
        assertEq(reentrantToken.totalSupply(), 0);
        assertEq(reentrantToken.balanceOf(alice), 0);
        assertEq(reentrantToken.balanceOf(address(this)), 0);
        assertEq(reentrantToken.vault(), address(0));
        assertFalse(reentrantToken.reenterOnTransfer());
        assertFalse(reentrantToken.reentrantCallBlocked());
    }

    function testMockReentrantERC223SettersAndMintState() external {
        MockReentrantERC223 reentrantToken = new MockReentrantERC223();

        reentrantToken.setVault(address(vault));
        reentrantToken.setReenterOnTransfer(true);
        reentrantToken.mint(alice, 15 ether);

        assertEq(reentrantToken.vault(), address(vault));
        assertTrue(reentrantToken.reenterOnTransfer());
        assertEq(reentrantToken.balanceOf(alice), 15 ether);
    }

    function testMockReentrantERC223InsufficientTransferReturnsFalse() external {
        MockReentrantERC223 reentrantToken = new MockReentrantERC223();

        vm.prank(alice);
        bool ok = reentrantToken.transfer(bob, 1 ether);

        assertFalse(ok);
        assertEq(reentrantToken.balanceOf(alice), 0);
        assertEq(reentrantToken.balanceOf(bob), 0);
    }

    function testFuzzMockReentrantERC223TransferWithoutData(uint256 mintAmount, uint256 transferAmount) external {
        mintAmount = bound(mintAmount, 1, INITIAL_SUPPLY);
        transferAmount = bound(transferAmount, 1, mintAmount);

        MockReentrantERC223 reentrantToken = new MockReentrantERC223();
        reentrantToken.mint(alice, mintAmount);

        vm.prank(alice);
        bool ok = reentrantToken.transfer(bob, transferAmount);

        assertTrue(ok);
        assertEq(reentrantToken.balanceOf(alice), mintAmount - transferAmount);
        assertEq(reentrantToken.balanceOf(bob), transferAmount);
    }

    function testFuzzMockReentrantERC223TransferWithData(uint256 mintAmount, uint256 transferAmount, bytes memory data)
        external
    {
        vm.assume(data.length <= 128);
        mintAmount = bound(mintAmount, 1, INITIAL_SUPPLY);
        transferAmount = bound(transferAmount, 1, mintAmount);

        MockReentrantERC223 reentrantToken = new MockReentrantERC223();
        MockRecipientRecorder recipient = new MockRecipientRecorder();
        reentrantToken.mint(alice, mintAmount);

        vm.prank(alice);
        bool ok = reentrantToken.transfer(address(recipient), transferAmount, data);

        assertTrue(ok);
        assertEq(reentrantToken.balanceOf(alice), mintAmount - transferAmount);
        assertEq(reentrantToken.balanceOf(address(recipient)), transferAmount);
        assertEq(recipient.lastFrom(), alice);
        assertEq(recipient.lastValue(), transferAmount);
        assertEq(recipient.lastData(), data);
        assertEq(recipient.callbackCount(), 1);
    }

    function testFuzzMockReentrantERC223ApproveAllowanceTransferFrom(
        address owner,
        address spender,
        address to,
        uint256 amount
    ) external {
        MockReentrantERC223 reentrantToken = new MockReentrantERC223();

        bool approved = reentrantToken.approve(spender, amount);
        uint256 allowed = reentrantToken.allowance(owner, spender);
        bool moved = reentrantToken.transferFrom(owner, to, amount);

        assertTrue(approved);
        assertEq(allowed, INITIAL_SUPPLY);
        assertFalse(moved);
    }

    function testNonReentrantBlocksRecursiveWithdraw() external {
        MockReentrantERC223 reentrantToken = new MockReentrantERC223();
        VerifundBasicVault reentrantVault = new VerifundBasicVault(address(reentrantToken));

        reentrantToken.setVault(address(reentrantVault));
        reentrantToken.mint(alice, 100 ether);

        vm.prank(alice);
        bool depositOk = reentrantToken.transfer(address(reentrantVault), 100 ether);
        assertTrue(depositOk);

        reentrantToken.setReenterOnTransfer(true);

        vm.prank(alice);
        reentrantVault.withdraw(10 ether);

        assertTrue(reentrantToken.reentrantCallBlocked());
    }

    /*//////////////////////////////////////////////////////////////
                         TESTING HELPERCONFIGS
    //////////////////////////////////////////////////////////////*/

    function testHelperConfigVaultMainnetConfig() external {
        MockReentrantERC223 mainnetToken = new MockReentrantERC223();
        vm.setEnv("MAINNET_TOKEN_ADDRESS", vm.toString(address(mainnetToken)));

        HelperConfigVault.VaultDeployConfig memory config =
            helperConfigVault.getNetworkConfigByChainId(NetworkConfigModule.CHAIN_ID_MAINNET);

        assertEq(config.tokenAddress, address(mainnetToken));
    }

    function testHelperConfigVaultSepoliaConfig() external {
        MockReentrantERC223 sepoliaToken = new MockReentrantERC223();
        vm.setEnv("SEPOLIA_TOKEN_ADDRESS", vm.toString(address(sepoliaToken)));

        HelperConfigVault.VaultDeployConfig memory config =
            helperConfigVault.getNetworkConfigByChainId(NetworkConfigModule.CHAIN_ID_SEPOLIA);

        assertEq(config.tokenAddress, address(sepoliaToken));
    }

    function testHelperConfigVaultUnsupportedChainReverts(uint256 chainId) external {
        vm.assume(chainId != NetworkConfigModule.CHAIN_ID_MAINNET);
        vm.assume(chainId != NetworkConfigModule.CHAIN_ID_SEPOLIA);

        vm.expectRevert(abi.encodeWithSelector(NetworkConfigModule.UnsupportedChainId.selector, chainId));
        helperConfigVault.getNetworkConfigByChainId(chainId);
    }

    function testHelperConfigVaultGetActiveDefaultNamespace() external {
        MockReentrantERC223 baseToken = new MockReentrantERC223();
        MockReentrantERC223 overrideToken = new MockReentrantERC223();

        vm.chainId(NetworkConfigModule.CHAIN_ID_SEPOLIA);
        vm.setEnv("SEPOLIA_TOKEN_ADDRESS", vm.toString(address(baseToken)));
        vm.setEnv("VAULT_TOKEN_ADDRESS", vm.toString(address(overrideToken)));

        HelperConfigVault.VaultDeployConfig memory config = helperConfigVault.getActiveNetworkConfig();

        assertEq(config.tokenAddress, address(overrideToken));
    }

    function testHelperConfigVaultGetActiveWithPrefixOverride() external {
        MockReentrantERC223 baseToken = new MockReentrantERC223();
        MockReentrantERC223 overrideToken = new MockReentrantERC223();

        vm.chainId(NetworkConfigModule.CHAIN_ID_MAINNET);
        vm.setEnv("MAINNET_TOKEN_ADDRESS", vm.toString(address(baseToken)));
        vm.setEnv("DEPLOY_X_VAULT_TOKEN_ADDRESS", vm.toString(address(overrideToken)));

        HelperConfigVault.VaultDeployConfig memory config =
            helperConfigVault.getActiveNetworkConfigWithPrefix("DEPLOY_X");

        assertEq(config.tokenAddress, address(overrideToken));
    }

    function testHelperConfigVaultRejectsInvalidTokenAddress() external {
        address invalidTokenAddress = makeAddr("invalidTokenAddress");

        vm.chainId(NetworkConfigModule.CHAIN_ID_SEPOLIA);
        vm.setEnv("SEPOLIA_TOKEN_ADDRESS", vm.toString(address(token)));
        vm.setEnv("VAULT_TOKEN_ADDRESS", vm.toString(invalidTokenAddress));

        vm.expectRevert(
            abi.encodeWithSelector(HelperConfigVault.InvalidVaultTokenAddress.selector, invalidTokenAddress)
        );
        helperConfigVault.getActiveNetworkConfig();
    }

    /*//////////////////////////////////////////////////////////////
                          TESTING DEPLOYVAULT
    //////////////////////////////////////////////////////////////*/

    // function testDeployVaultRunDefaultNamespaceSmoke() external {
    //     MockReentrantERC223 fallbackMainnetToken = new MockReentrantERC223();
    //     address fallbackTokenAddress = address(fallbackMainnetToken);

    //     vm.chainId(NetworkConfigModule.CHAIN_ID_MAINNET);
    //     vm.setEnv("MAINNET_TOKEN_ADDRESS", vm.toString(fallbackTokenAddress));
    //     // Critical for fork stability: default namespace uses VAULT_TOKEN_ADDRESS
    //     // as top-priority override. Force it to a valid in-test contract.
    //     vm.setEnv("VAULT_TOKEN_ADDRESS", vm.toString(fallbackTokenAddress));

    //     DeployVault deployVault = new DeployVault();

    //     VerifundBasicVault deployedVault = deployVault.run();
    //     assertTrue(address(deployedVault) != address(0));
    //     assertEq(address(deployedVault.i_token()), fallbackTokenAddress);
    // }

    function testDeployVaultRunWithEnvPrefixDeploysUsingPrefixedNamespace() external {
        MockReentrantERC223 baseToken = new MockReentrantERC223();
        MockReentrantERC223 prefixedToken = new MockReentrantERC223();

        vm.chainId(NetworkConfigModule.CHAIN_ID_SEPOLIA);
        vm.setEnv("SEPOLIA_TOKEN_ADDRESS", vm.toString(address(baseToken)));
        vm.setEnv("VAULT_DEPLOY_VAULT_TOKEN_ADDRESS", vm.toString(address(prefixedToken)));

        DeployVault deployVault = new DeployVault();
        address resolvedByDeployScript = deployVault.resolvedTokenAddressForRunWithPrefix("VAULT_DEPLOY");
        VerifundBasicVault deployedVault = deployVault.runWithEnvPrefix("VAULT_DEPLOY");

        assertEq(resolvedByDeployScript, address(prefixedToken));
        assertEq(address(deployedVault.i_token()), address(prefixedToken));
    }
}
