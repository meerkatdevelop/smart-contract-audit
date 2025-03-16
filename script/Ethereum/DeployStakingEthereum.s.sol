// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Script} from "forge-std/Script.sol";
import {Staking} from "../../src/Staking.sol";
import "forge-std/Test.sol";

contract DeployStaking is Script {
    
    uint256[][3] phases_;
    function run() external returns (Staking) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address rewardToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT Ethereum
        address owner = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
        uint256 rewardsTokenPerBlock = 100000;
        uint256 lockTime = 172800;
        uint256 endBlock = 22125770;
        Staking staking = new Staking(rewardToken, owner, rewardsTokenPerBlock, lockTime, endBlock);
        vm.stopBroadcast();
        return staking;
    }
}