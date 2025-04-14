// SPDX-License-Identifier: MIT

// Testing in Mainnet:
// forge test --fork-url https://eth.llamarpc.com -vvvvv --via-ir --match-test

pragma solidity 0.8.24;

import "../src/Staking.sol";
import "../src/Presale.sol";
import "../src/MeerkatToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/Test.sol";

contract StakingTest is Test {
    using SafeERC20 for IERC20;

    address deployer = vm.addr(1);
    address buyer = 0x4597C25089363788e75a32d0FbB5B334862570b6; // Address with Funds in Ethereum and BSC

    // MeerkatToken
    MeerkatToken meerkatToken;
    address meerkatTokenAddress; 

    // Presale
    Presale presale;
    address usdtAddress_ = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT in ethereum Mainnet
    address usdcAddress_ = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC in ethereum Mainnet
    address aggregatorContract_ = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD in Ethereum Mainnet
    address stakingContract= vm.addr(3); // @audit define correct contract
    address paymentWallet_ = vm.addr(2);
    address ownerWallet = vm.addr(4);
    uint256[][3] phases_;
    uint256 maxTotalSellingAmount_ = 10000000000000 * 1e18; 
    uint256 usdLimitPhase0_ = 1000000 * 1e18;
    uint256 usdLimitPhase1_ = 1000000 * 1e18;


    // Staking
    Staking staking;
    address rewardTokenAddress_;
    address presaleContract_;
    uint256 rewardTokensPerBlock_ = 304 * 10^18; 
    uint lockTime_ = 604800;
    uint endBlock_ = block.timestamp + 30 days;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy Meerkat Token
        meerkatToken = new MeerkatToken(deployer);
        meerkatTokenAddress = address(meerkatToken);

        // Deploy Staking
        rewardTokenAddress_ = meerkatTokenAddress;
        staking = new Staking(rewardTokenAddress_, deployer, rewardTokensPerBlock_, lockTime_, endBlock_);
        staking.setStakingEnabled(true);

        // Deploy Presale
        stakingContract = address(staking);
        phases_[0] = [200_000_000 * 10**18, 5000, 2737897226];
        phases_[1] = [700_000_000 * 10**18, 15000, 2737997226];
        phases_[2] = [700_000_000 * 10**18, 30000, 2738897226];
        presale = new Presale(meerkatTokenAddress, usdtAddress_, usdcAddress_, aggregatorContract_, stakingContract, paymentWallet_, ownerWallet, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        uint256 balanceOfMeerkat = IERC20(meerkatToken).balanceOf(deployer);
        IERC20(meerkatToken).transfer(address(presale), balanceOfMeerkat);
        presaleContract_ = address(presale);

        staking.setPresale(address(presale));
        vm.stopPrank();

        vm.startPrank(paymentWallet_);
        presale.unpausePresale();
        vm.stopPrank();
    }

    function testDeployedCorrectly() public view {
        address presaleContract = staking.presaleContract();
        assert(presaleContract == presaleContract_ && presaleContract != address(0));
    }

    function testCanBuyAndStakeWithStableCorrectlyAndStakes() public { // Works
        vm.startPrank(buyer);
        uint256 amount = 2 * 1e6;
        address token = usdcAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount, true);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);
        assert(userTokenBalanceAfter == 0 && userTokenBalanceBefore == 0);

        vm.stopPrank();
    }

    function testCanBuyAndStakeWithStableCorrectlyAndUpdatesInfo() public { // Works
        vm.startPrank(buyer);
        uint256 amount = 2 * 1e6;
        address token = usdcAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount, true);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 0);
        assert(stakerAmount == 400 * 1e18);

        vm.stopPrank();
    }

    function testUserCanBuyAndStake2Times() public { // Works
        vm.startPrank(buyer);

        // 1st time
        uint256 amount = 1 * 1e6;
        address token = usdcAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount, true);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount == 200 * 1e18);
        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 0);

        // 2nd time
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore2 = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount, true);
        uint256 userTokenBalanceAfter2 = presale.userTokenBalance(buyer);
        assert(userTokenBalanceBefore2 == 0 && userTokenBalanceAfter2 == 0);

        (uint256 stakerAmount2,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount2 == stakerAmount * 2);
        vm.stopPrank();
    }

    function testUserShouldNotHarvestOnSecondStake() public { // Works
        vm.startPrank(buyer);

        uint256 noBalanceBefore = IERC20(meerkatToken).balanceOf(buyer);
        // 1st time
        uint256 amount = 1 * 1e6;
        address token = usdcAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount, true);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 0);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount == 200 * 1e18);

        // 2nd time
        IERC20(token).approve(address(presale), amount);
        presale.buyWithStable(token, amount, true);

        (uint256 stakerAmount2,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount2 == stakerAmount * 2);

        uint256 noBalanceAfter = IERC20(meerkatToken).balanceOf(buyer);
        assert(noBalanceBefore == 0 && noBalanceAfter == 0);
        vm.stopPrank();
    }

    function testUserCanStake3TimesWithoutReceivingTokens() public { // Works
        vm.startPrank(buyer);
        uint256 noBalanceBefore = IERC20(meerkatToken).balanceOf(buyer);
        // 1st time
        uint256 amount = 1 * 1e6;
        address token = usdcAddress_;
        IERC20(token).approve(address(presale), amount);
        presale.buyWithStable(token, amount, true);
        uint256 noBalanceAfter0 = IERC20(meerkatToken).balanceOf(buyer);
        assert(noBalanceBefore == 0 && noBalanceAfter0 == 0);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount == 200 * 1e18);

        // 2nd time
        vm.roll(block.number + 200000);
        IERC20(token).approve(address(presale), amount);
        presale.buyWithStable(token, amount, true);

        (uint256 stakerAmount2,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount2 == stakerAmount * 2);

        uint256 noBalanceAfter = IERC20(meerkatToken).balanceOf(buyer);
        assert(noBalanceBefore == 0 && noBalanceAfter == 0);

        // 3rd time
        vm.roll(block.number + 400000);

        IERC20(token).approve(address(presale), amount);
        presale.buyWithStable(token, amount, true);

        (uint256 stakerAmount3,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount3 == stakerAmount * 3);

        uint256 noBalanceAfter2 = IERC20(meerkatToken).balanceOf(buyer);
        assert(noBalanceBefore == 0 && noBalanceAfter2 == 0);
        
        vm.stopPrank();
    }

     function testUserCanClaimAndStakeCorrectly() public { // Works
        vm.startPrank(buyer);
        uint256 amount = 10000000000000000; // 0.01 Ether - 30 USD
        vm.deal(buyer, amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        uint256 receiverETHBalanceBefore = address(paymentWallet_).balance;
        presale.buyWithETH{value: amount}(false);
        uint256 receiverETHBalanceAfter = address(paymentWallet_).balance;
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter != 0);
        assert(receiverETHBalanceAfter == receiverETHBalanceBefore + amount);
        vm.stopPrank();

        vm.startPrank(paymentWallet_);
        presale.startClaim(true);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 balanceBefore = IERC20(meerkatTokenAddress).balanceOf(buyer);
        presale.claim(true);
        uint256 balanceAfter = IERC20(meerkatTokenAddress).balanceOf(buyer);
        assert(balanceBefore == 0);
        assert(balanceAfter == 0);

        uint256 userTokenBalancePending = presale.userTokenBalance(buyer);
        assert(userTokenBalancePending == 0);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount == userTokenBalanceAfter);
        vm.stopPrank();
    }

    function testUserCanHarvestRewardAfterStaking() public {
        vm.startPrank(buyer);
        // uint256 amount = 2 * 1e18;
        uint256 amount = 10000000000000000; // 0.01 Ether - 30 USD
        vm.deal(buyer, amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        uint256 receiverETHBalanceBefore = address(paymentWallet_).balance;
        presale.buyWithETH{value: amount}(false);
        uint256 receiverETHBalanceAfter = address(paymentWallet_).balance;
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter != 0);
        assert(receiverETHBalanceAfter == receiverETHBalanceBefore + amount);
        vm.stopPrank();

        vm.startPrank(paymentWallet_);
        presale.startClaim(true);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 balanceBefore = IERC20(meerkatTokenAddress).balanceOf(buyer);
        presale.claim(true);
        uint256 balanceAfter = IERC20(meerkatTokenAddress).balanceOf(buyer);
        assert(balanceBefore == 0);
        assert(balanceAfter == 0);

        uint256 userTokenBalancePending = presale.userTokenBalance(buyer);
        assert(userTokenBalancePending == 0);

        (uint256 stakerAmount,,,,) = staking.poolStakers(buyer);
        assert(stakerAmount == userTokenBalanceAfter);

        vm.roll(block.number + 4000000);
        uint256 userLockedRewardBefore = staking.userLockedRewards(buyer);
        staking.harvestRewards();
        uint256 userLockedRewardAfter = staking.userLockedRewards(buyer);
        assert(userLockedRewardBefore == 0 && userLockedRewardAfter > 0);
        vm.stopPrank();

    

    }
}