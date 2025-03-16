// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MeerkatToken is ERC20 {
  uint256 _totalSupply = 6_000_000_000 * 1e18;

  constructor(address distributorAddress_) ERC20('Meerkat', 'MERKT') {
    _mint(distributorAddress_, _totalSupply);
  }
}