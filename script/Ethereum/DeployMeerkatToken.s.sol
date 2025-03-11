// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Script} from "forge-std/Script.sol";
import {MeerkatToken} from "../../src/MeerkatToken.sol";
import "forge-std/Test.sol";

contract DeployMeerkatToken is Script {
    
    uint256[][3] phases_;
    function run() external returns (MeerkatToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address distributorWallet = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
        MeerkatToken token = new MeerkatToken(distributorWallet);
        vm.stopBroadcast();
        return token;
    }
}