// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../src/PresaleL2.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

contract PresaleL2Test is Test {

    struct PhaseData {
        uint256 currentPhase;
        uint256 phaseMaxTokens;
        uint256 phasePrice;
        uint256 phaseEndTime;
    }

    address deployer = vm.addr(1);
    address buyer = 0x4597C25089363788e75a32d0FbB5B334862570b6; // Address with BNB/USDT/USDC in BSC
    PresaleL2 presale;
    address usdtAddress_ = 0x55d398326f99059fF775485246999027B3197955;
    address usdcAddress_ = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address aggregatorContract_ = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e; // ETH/USD in BSC
    address paymentWallet_ = vm.addr(2);
    address ownerWallet = vm.addr(3);
    uint256[][3] phases_;
    uint256 maxTotalSellingAmount_ = 10000000000000 * 1e18; 
    uint256 usdLimitPhase0_ = 2 * 1e18;
    uint256 usdLimitPhase1_ = 2 * 1e18;

    address randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(deployer);
        phases_[0] = [200_000_000 * 10**18, 5000, 1737897226];
        phases_[1] = [700_000_000 * 10**18, 15000, 1737997226];
        phases_[2] = [700_000_000 * 10**18, 30000, 1738897226];
        presale = new PresaleL2(usdtAddress_, usdcAddress_, aggregatorContract_, paymentWallet_, ownerWallet, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        presale.unpausePresale();
        vm.stopPrank();
    }

    function testPhasesSetCorrectly() public view {
        PresaleL2.PhaseData memory currentPhaseData = presale.getCurrentPhaseData();
        assert(currentPhaseData.phaseMaxTokens == phases_[0][0]);
    }

    function testEthOracleIsWorkingCorrectly() public view {
        uint256 price = presale.getLatestPrice();
        assert(price != 0);
    }

    function testRevertIfRandomIncreasesUserBalance() public {
        vm.expectRevert();
        uint256 amount_ = 100 * 1e18;
        presale.increaseUserBalance(randomUser, amount_);
    }

    function testIncreasesUserBalanceCorrectly() public {
        vm.startPrank(paymentWallet_);
        uint256 balanceBefore = presale.userTokenBalance(randomUser);
        uint256 amount_ = 100 * 1e18;
        presale.increaseUserBalance(randomUser, amount_);
        uint256 balanceAfter = presale.userTokenBalance(randomUser);

        assert(balanceAfter == balanceBefore + amount_);
        vm.stopPrank();
    }

    function testIncreasesUserBalanceCorrectlyWithUSD() public {
        vm.startPrank(paymentWallet_);
        uint256 usdBefore = presale.usdRaised();
        uint256 amount_ = 100 * 1e18;
        presale.increaseUserBalance(randomUser, amount_);
        uint256 usdAfter = presale.usdRaised();

        assert(usdAfter > usdBefore);
        vm.stopPrank();
    }

    function testIncreasesUserBalanceCorrectlyWithtotalTokensSold() public {
        vm.startPrank(paymentWallet_);
        uint256 totalTokensSoldBefore = presale.totalTokensSold();
        uint256 amount_ = 100 * 1e18;
        presale.increaseUserBalance(randomUser, amount_);
        uint256 totalTokensSoldAfter = presale.totalTokensSold();

        assert(totalTokensSoldAfter == totalTokensSoldBefore + amount_);
        vm.stopPrank();
    }

    function testOnlyOwnerCanBlackList() public {
        vm.expectRevert();
        presale.blacklistUser(randomUser);
    }

    function testOnlyOwnerCanUnBlackList() public {
        vm.expectRevert();
        presale.removeFromBlacklist(randomUser);
    }

    function testOwnerCanBlackListCorrectly() public {
        vm.startPrank(paymentWallet_);
        bool before = presale.isBlacklisted(randomUser);
        presale.blacklistUser(randomUser);
        bool after2 = presale.isBlacklisted(randomUser);
        assert(before == false && after2 == true);
        vm.stopPrank();
    }

    function testOwnerCanUnBlackListCorrectly() public {
        vm.startPrank(paymentWallet_);
        bool before = presale.isBlacklisted(randomUser);
        presale.blacklistUser(randomUser);
        bool after2 = presale.isBlacklisted(randomUser);
        assert(before == false && after2 == true);
        presale.removeFromBlacklist(randomUser);
        bool after3 = presale.isBlacklisted(randomUser);
        assert(after3 == false);
        vm.stopPrank();
    }

    function testgetTokensFromStableWorksCorrectly() public view {
        uint256 amount = 1e18;
        uint256 tokensAmount = presale.getTokensFromUSDT(amount);
        uint256 expectedAmount = amount * 1e6 / phases_[0][1];
        assert(tokensAmount == expectedAmount && tokensAmount != 0);
    }

    function testgetTokensFromEthWorksCorrectly() public view {
        uint256 amount = 1e18;
        uint256 tokensAmount = presale.getTokensFromETH(amount);
        assert(tokensAmount != 0);

    }

    function testOnlyOwnerCanChangePhases() public {
        vm.expectRevert();
        phases_[0] = [100_000_000 * 10**18, 5000, 1737129600];
        phases_[1] = [100_000_000 * 10**18, 15000, 1737734400];
        phases_[2] = [100_000_000 * 10**18, 30000, 1738339200];
        presale.changePhases(phases_);
    }

    function testOwnerCanChangePhasesCorrectly() public {
        vm.startPrank(paymentWallet_);
        PresaleL2.PhaseData memory currentPhaseData = presale.getCurrentPhaseData();
        assert(currentPhaseData.phaseMaxTokens == phases_[0][0]);
        phases_[0] = [100_000_000 * 10**18, 5000, 1737129600];
        phases_[1] = [100_000_000 * 10**18, 15000, 1737734400];
        phases_[2] = [100_000_000 * 10**18, 30000, 1738339200];
        presale.changePhases(phases_);
        currentPhaseData = presale.getCurrentPhaseData();
        assert(currentPhaseData.phaseMaxTokens == phases_[0][0]);
        vm.stopPrank();
    }

    function testOnlyOwnerCanUpdateTotalSellingAmount() public {
        uint256 amount = 5;
        vm.expectRevert();
        presale.updatemaxTotalSellingAmount(amount);
    }

    function testOnlyOwnerCanUpdatePaymentWallet() public {
        vm.expectRevert();
        presale.updatePaymentWallet(randomUser);
    }

    function testOwnerCanUpdateTSA() public {
        vm.startPrank(paymentWallet_);
        uint256 amount = 5;
        presale.updatemaxTotalSellingAmount(amount);
        uint256 updatedAmount = presale.maxTotalSellingAmount();
        assert(amount == updatedAmount);
        vm.stopPrank();
    }

    function testOwnerCanUpdatePW() public {
        vm.startPrank(paymentWallet_);
        presale.updatePaymentWallet(randomUser);
        address updatedWallet = presale.paymentWallet();
        assert(updatedWallet == randomUser);
        vm.stopPrank();
    }

    function testCanNotBuyWithRandomToken() public {
        address randomToken = vm.addr(6);
        uint256 amount = 5;
        vm.expectRevert("Token not supported");
        presale.buyWithStable(randomToken, amount);
    }

    function testCanBuyWithStableCorrectly() public {
        vm.startPrank(buyer);
        uint256 amount = 2 * 1e18;
        address token = usdtAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 400 * 1e18);
        vm.stopPrank();
    }

    function testCanbuyWithETHCorrectly() public {
        vm.startPrank(buyer);
        uint256 amount = 2 * 1e18;
        vm.deal(buyer, amount);
        uint256 receiverETHBalanceBefore = presale.userTokenBalance(buyer);
        uint256 userTokenBalanceBefore = address(paymentWallet_).balance;
        presale.buyWithETH{value: amount}();
        uint256 receiverETHBalanceAfter = address(paymentWallet_).balance;
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(receiverETHBalanceBefore == 0 && receiverETHBalanceAfter == amount);
        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter != 0);
        vm.stopPrank();
    }

    function testCanBuyBeforeLimitCorrectly() public {
        vm.startPrank(buyer);
        uint256 amount = 1 * 1e18;
        address token = usdtAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 200 * 1e18);
        vm.stopPrank();
    }

    function testCanNotBuyAboveThreshold() public {
        vm.startPrank(buyer);
        uint256 amount = 1 * 1e18;
        address token = usdtAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 200 * 1e18);
        vm.stopPrank();

        uint256 newAmount = 2 * 1e18;
        IERC20(token).approve(address(presale), newAmount);
        vm.expectRevert("Phase 0 completed");
        presale.buyWithStable(token, newAmount);
    }

    function testUserCanBuy2TimesWithoutPhaseShit() public {
        vm.startPrank(deployer);
        phases_[0] = [200_000_000 * 10**18, 5000, 1737897226];
        phases_[1] = [700_000_000 * 10**18, 15000, 1737997226];
        phases_[2] = [700_000_000 * 10**18, 30000, 1738897226];
        uint256 usdLimitPhase0 = 100 * 1e18;
        uint256 usdLimitPhase1 = 100 * 1e18;
        presale = new PresaleL2(usdtAddress_, usdcAddress_, aggregatorContract_, paymentWallet_, ownerWallet, phases_, maxTotalSellingAmount_, usdLimitPhase0, usdLimitPhase1);
        vm.stopPrank();

        vm.startPrank(buyer);

        PresaleL2.PhaseData memory currentPhase = presale.getCurrentPhaseData();
        uint256 amount = 1 * 1e18;
        address token = usdtAddress_;
        IERC20(token).approve(address(presale), amount);
        uint256 userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount);
        uint256 userTokenBalanceAfter = presale.userTokenBalance(buyer);

        assert(userTokenBalanceBefore == 0 && userTokenBalanceAfter == 200 * 1e18);
        assert(currentPhase.currentPhase == 0);

        IERC20(token).approve(address(presale), amount);
        userTokenBalanceBefore = presale.userTokenBalance(buyer);
        presale.buyWithStable(token, amount);
        userTokenBalanceAfter = presale.userTokenBalance(buyer);
        currentPhase = presale.getCurrentPhaseData();

        assert(userTokenBalanceAfter == userTokenBalanceBefore + 200 * 1e18);
        assert(currentPhase.currentPhase == 0);
        vm.stopPrank();
    }

    

}