// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PresaleL2} from "../../src/PresaleL2.sol";
import "../../src/interfaces/IPresaleL2.sol";
import "forge-std/Test.sol";

contract DebugTxs is Script {

    address javiAddress = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
    address PresaleL2Address = 0x276ddbCaAD6b2F98abf37e39F08e5226fCF1B082;

    function run() external {
        vm.startPrank(javiAddress);
        uint256 value = 100000000000000;
        IPresaleL2(PresaleL2Address).buyWithETH{value: value}();
        vm.stopPrank();
    }   

}