// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MeerkatClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    mapping(address => bool) public hasClaimed;
    address public signerAddress;
    address public meerkatTokenAddress;
    bool public claimEnabled;

    constructor(address ownerAddress_, address signerAddress_, address meerkatTokenAddress_) Ownable(ownerAddress_) {
        signerAddress = signerAddress_;
        meerkatTokenAddress = meerkatTokenAddress_;
    }

    function claim(uint256 amount_, bytes memory signature_) external nonReentrant {
        require(!hasClaimed[msg.sender], "Already claimed");

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount_));
        bytes32 messageHashSigned = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        address signer = ECDSA.recover(messageHashSigned, signature_);
        require(signer == signerAddress, "startStake: invalid signature");

        hasClaimed[msg.sender] = true;
        IERC20(meerkatTokenAddress).safeTransfer(msg.sender, amount_);
    }

   /**
   * @dev To withdraw the contract balance in emergency case of any token
   * @param tokenToWithdraw_ address of the token to withdraw
   * @param receiverAddress_ address to receive tokens
   */
  function emergencyWithdraw(address tokenToWithdraw_, address receiverAddress_) external onlyOwner {
    uint256 contractBalance = IERC20(tokenToWithdraw_).balanceOf(address(this));

    IERC20(tokenToWithdraw_).safeTransfer(receiverAddress_, contractBalance);
  }
}