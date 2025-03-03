// SPDX-License-Identifier: MIT
import "../PresaleL2.sol";
pragma solidity 0.8.24;

interface IPresaleL2 {
  function buyWithETH() external payable;
  function getCurrentPhaseData() external view returns (PresaleL2.PhaseData memory);
  function totalTokensSold() external returns(uint256);
  function phases(uint256, uint256) external returns(uint256);
  function currentPhase() external returns(uint256);
}