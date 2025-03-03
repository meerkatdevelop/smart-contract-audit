// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../../src/PresaleL2.sol";
import "../../src/interfaces/IPresaleL2.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

contract PresaleL2Test is Test {

    address javiAddress = 0x56E4CF839281f06c6B25a2037C5797C40D35fF2c;
    address PresaleL2Address = 0x276ddbCaAD6b2F98abf37e39F08e5226fCF1B082;
    IPresaleL2 presale;

    function setUp () public {
        presale = IPresaleL2(PresaleL2Address);
    }

    function testRevertTx() public {
        vm.startPrank(javiAddress);
        uint256 value = 100000000000000;
        uint256 totalTokensSold = presale.totalTokensSold();
        console.log("totalTokensSold", totalTokensSold);
        uint256 currentPhase = presale.currentPhase();
        console.log("currentPhase", currentPhase);
        uint256 amountPhases = presale.phases(currentPhase, 0);
        console.log("amountPhases", amountPhases);
        //presale.buyWithETH{value: value}();
        vm.stopPrank();
    }
}