// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MeerkatToken is ERC20 {
  uint256 totalSupply = 600000000 * 1e18;

  constructor(address distributorAddress_) ERC20('Meerkat', 'MRKT') {
    _mint(distributorAddress_, totalSupply);
  }
}