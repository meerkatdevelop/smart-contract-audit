// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PresaleL2} from "../../src/PresaleL2.sol";
import "forge-std/Test.sol";

contract DeployPresaleL2BSC is Script {
    uint256[][3] phases_;

    function run() external returns (PresaleL2) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address usdtAddress_ = 0x55d398326f99059fF775485246999027B3197955; // USDT BSC
        address usdcAddress_ = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // USDC BSC
        address aggregatorContract_ = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e; // PriceFeed ETH/USD en BASE
        address paymentWallet_ = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c; 
        uint256 maxTotalSellingAmount_ = 10000000000000 * 1e18;  // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase0_ = 2 * 1e18; // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase1_ = 2 * 1e18; // @audit CAMBIAR A FINAL

        phases_[0] = [20000  * 10**18, 5000, 1737897226]; // @audit CAMBIAR A FINAL
        phases_[1] = [20000  * 10**18, 15000, 1737997226]; // @audit CAMBIAR A FINAL
        phases_[2] = [20000  * 10**18, 30000, 1738897226]; // @audit CAMBIAR A FINAL
        
        PresaleL2 presale = new PresaleL2(usdtAddress_, usdcAddress_, aggregatorContract_, paymentWallet_, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);

        vm.stopBroadcast();
        return presale;
    }
}