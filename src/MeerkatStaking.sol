// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IPresale.sol';
import "forge-std/Test.sol";

contract MeerkatStaking is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public stakeToken;
  address public presaleContract;
  uint256 public tokensStakedByPresale;
  uint256 public tokensStaked;

  address public presale;
  uint256 public rewardTokensPerBlock;
  uint public lockedTime;
  uint public endBlock;
  bool public harvestLock;

  bool public stakingEnabled;
  bool public withdrawEnabled;

  uint256 private lastRewardedBlock;
  uint256 private accumulatedRewardsPerShare;
  uint256 private constant REWARDS_PRECISION = 1e12;

  struct PoolStaker {
    uint256 amount;
    uint256 stakedTime;
    uint256 lastUpdatedBlock;
    uint256 Harvestedrewards;
    uint256 rewardDebt;
  }

  mapping(address => PoolStaker) public poolStakers;
  mapping(address => uint) public userLockedRewards;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event HarvestRewards(address indexed user, uint256 amount);

  constructor(address rewardTokenAddress_, address presale_, uint256 rewardTokensPerBlock_, uint lockTime_, uint endBlock_) Ownable(msg.sender) {
    stakeToken = IERC20(rewardTokenAddress_);
    presale = presale_;
    rewardTokensPerBlock = rewardTokensPerBlock_;
    lockedTime = lockTime_;
    endBlock = endBlock_;
    harvestLock = true;
  }

  modifier onlyWhenStakingEnabled() {
    require(stakingEnabled, "Staking not enabled");
    _;
  }

  modifier onlyWithdrawEnabled() {
    require(withdrawEnabled, "Withdraw not enabled");
    _;
  }

  /**
   * @dev Stake tokens to the pool
   */
  function deposit(uint256 amount_) external onlyWhenStakingEnabled {
    require(block.number < endBlock, 'staking has been ended');
    require(amount_ > 0, "Deposit amount can't be zero");

    PoolStaker storage staker = poolStakers[msg.sender];

    harvestRewards();

    staker.amount += amount_;
    staker.rewardDebt = (staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION;
    staker.stakedTime = block.timestamp;
    staker.lastUpdatedBlock = block.number;

    tokensStaked += amount_;

    emit Deposit(msg.sender, amount_);
    stakeToken.safeTransferFrom(msg.sender, address(this), amount_);
  }

  /**
   * @dev Withdraw all staked tokens from existing pool
   */
  function withdraw() external onlyWithdrawEnabled {
    
    PoolStaker memory staker = poolStakers[msg.sender];
    uint256 amount = staker.amount;
    require(staker.stakedTime + lockedTime <= block.timestamp, 'You are not allowed to withdraw before locked Time');
    require(amount > 0, "Withdraw amount can't be zero");

    harvestRewards();

    delete poolStakers[msg.sender];

    tokensStaked -= amount;

    emit Withdraw(msg.sender, amount);
    stakeToken.safeTransfer(msg.sender, amount);
  }

   /**
   * @dev Harvest user rewards
   */
  function harvestRewards() public {
    _harvestRewards(msg.sender);
  }

  /**
   * @dev Harvest user rewards
   */
  function _harvestRewards(address user_) private {
    updatePoolRewards();

    PoolStaker storage staker = poolStakers[user_];
    uint256 rewardsToHarvest = ((staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION) - staker.rewardDebt;

    if (rewardsToHarvest == 0) return;

    staker.Harvestedrewards += rewardsToHarvest;
    staker.rewardDebt = (staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION;

    if (!harvestLock ) {
      if (userLockedRewards[user_] > 0) {
        rewardsToHarvest += userLockedRewards[user_];
        userLockedRewards[user_] = 0;
      }
      emit HarvestRewards(user_, rewardsToHarvest);
      stakeToken.safeTransfer(user_, rewardsToHarvest);
    } else {
      userLockedRewards[user_] += rewardsToHarvest;
    }
  }

  /**
   * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
   */
  function updatePoolRewards() private {
    if (tokensStaked == 0) {
      lastRewardedBlock = block.number;
      return;
    }
   
    uint256 blocksSinceLastReward = block.number > endBlock ? endBlock - lastRewardedBlock : block.number - lastRewardedBlock;
    uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
    accumulatedRewardsPerShare = accumulatedRewardsPerShare + ((rewards * REWARDS_PRECISION) / tokensStaked);
    lastRewardedBlock = block.number > endBlock ? endBlock : block.number;
  }

  /**
   *@dev To get the number of rewards that user can get
   */
  function getRewards(address user_) public view returns (uint) {
    if (tokensStaked == 0) return 0;

    uint256 blocksSinceLastReward = block.number > endBlock ? endBlock - lastRewardedBlock : block.number - lastRewardedBlock;
    uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
    uint256 accCalc = accumulatedRewardsPerShare + ((rewards * REWARDS_PRECISION) / tokensStaked);
    PoolStaker memory staker = poolStakers[user_];

    return ((staker.amount * accCalc) / REWARDS_PRECISION) - staker.rewardDebt + userLockedRewards[user_];
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

  /**
  * @dev To withdraw the contract balance in emergency case of ether
  * @param receiverAddress_ address to receive tokens
  */
  function emergencyEthWithdraw(address receiverAddress_) external onlyOwner {
    uint256 contractBalance = address(this).balance;

    (bool success, ) = receiverAddress_.call{value: contractBalance}("");
    require(success, "Transfer failed");
  }

  function setStakingEnabled(bool enabled_) external onlyOwner {
    stakingEnabled = enabled_;
  }

  function setWithdrawEnabled(bool enabled_) external onlyOwner {
    withdrawEnabled = enabled_;
  }


}