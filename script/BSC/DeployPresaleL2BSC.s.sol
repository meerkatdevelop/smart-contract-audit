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
        address aggregatorContract_ = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // PriceFeed BNB/USD en BSC
        address paymentWallet_ = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
        address ownerWallet_ = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
        uint256 maxTotalSellingAmount_ = 70000 * 1e18;  // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase0_ = 10 * 1e18; // @audit CAMBIAR A FINAL
        uint256 usdLimitPhase1_ = 10 * 1e18; // @audit CAMBIAR A FINAL
        phases_[0] = [20000  * 10**18, 500, 1741791600   ]; // @audit CAMBIAR A FINAL
        phases_[1] = [6667  * 10**18, 1500, 1741964400   ]; // @audit CAMBIAR A FINAL
        phases_[2] = [3333  * 10**18, 3000, 1742137200]; // @audit CAMBIAR A FINAL
        PresaleL2 presale = new PresaleL2(usdtAddress_, usdcAddress_, aggregatorContract_, paymentWallet_, ownerWallet_, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        vm.stopBroadcast();
        return presale;
    }
}