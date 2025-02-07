// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IStaking {
  function depositByPresale(address user_, uint256 amount_) external;
}