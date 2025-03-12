// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Script} from "forge-std/Script.sol";
import {Presale} from "../../src/Presale.sol";
import "forge-std/Test.sol";

contract DeployPresaleEthereum is Script {
    
    uint256[][3] phases_;
    function run() external returns (Presale) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address merkatTokenAddress = 0x1F082DB5D8Bf3F15CD4135405a39b3c11931Efac;
        address usdtAddress_ = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT Ethereum
        address usdcAddress_ = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC Ethereum
        address aggregatorContract_ = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // PriceFeed Ether/USD en Ethereum
        address stakingContract_ = 0xDd456f98734e542828c8c2c325FA5369e9eF77ce;
        address paymentWallet_ = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
        uint256 maxTotalSellingAmount_ = 70000 * 1e18;  // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase0_ = 10 * 1e18; // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase1_ = 10 * 1e18; // @audit CAMBIAR A FINAL
        phases_[0] = [20000  * 10**18, 500, 1741791600   ]; // @audit CAMBIAR A FINAL
        phases_[1] = [6667  * 10**18, 1500, 1741964400   ]; // @audit CAMBIAR A FINAL
        phases_[2] = [3333  * 10**18, 3000, 1742137200]; // @audit CAMBIAR A FINAL
        Presale presale = new Presale(merkatTokenAddress, usdtAddress_, usdcAddress_, aggregatorContract_, stakingContract_, paymentWallet_, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        vm.stopBroadcast();
        return presale;
    }
}