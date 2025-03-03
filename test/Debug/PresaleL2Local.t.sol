// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../../src/PresaleL2.sol";
import "../../src/interfaces/IPresaleL2.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

contract PresaleL2Test is Test {

    address javiAddress = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
    address PresaleL2Address = 0x276ddbCaAD6b2F98abf37e39F08e5226fCF1B082;
    uint256[][3] phases_;
    PresaleL2 presale;

    function setUp () public {
        vm.startPrank(javiAddress);
        address usdtAddress_ = 0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2; // USDT BASE
        address usdcAddress_ = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC BASE
        address aggregatorContract_ = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // PriceFeed ETH/USD en BASE
        address paymentWallet_ = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c; 
        uint256 maxTotalSellingAmount_ = 10000000000000 * 1e18;  // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase0_ = 10 * 1e18; // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase1_ = 20 * 1e18; // @audit CAMBIAR A FINAL

        phases_[0] = [20000  * 10**18, 5000, 27020000  ]; // @audit CAMBIAR A FINAL
        phases_[1] = [20000  * 10**18, 15000, 27120000  ]; // @audit CAMBIAR A FINAL
        phases_[2] = [20000  * 10**18, 30000, 27229000]; // @audit CAMBIAR A FINAL
        
        presale = new PresaleL2(usdtAddress_, usdcAddress_, aggregatorContract_, paymentWallet_, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        presale.unpausePresale();
        vm.stopPrank();
    }

    function testBuyWithEther() public {
        vm.startPrank(javiAddress);
        uint256 value = 100000000000000; // 0.0001
        vm.deal(javiAddress, value);
        presale.buyWithETH{value: value}();

        console.log("Second Buy");
        uint256 value2 = 100000000000000; // 0.0001
        vm.deal(javiAddress, value2); 
        presale.buyWithETH{value: value2}();

        console.log("Third buy");
        uint256 value3 = 1000000000000000; // 0.001
        vm.deal(javiAddress, value3);
        presale.buyWithETH{value: value3}();
        vm.stopPrank();
    }

    
}