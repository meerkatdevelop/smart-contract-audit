// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IPresale.sol';

contract Staking is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public stakeToken;
  address public presaleContract;
  uint256 public tokensStakedByPresale;
  uint256 public tokensStaked;

  uint256 private lastRewardedBlock;
  uint256 private accumulatedRewardsPerShare;
  uint256 public rewardTokensPerBlock;
  uint256 private constant REWARDS_PRECISION = 1e12;

  uint256 public lockedTime;
  bool public harvestLock;
  uint public endBlock;
  bool public withdrawEnabled;
  bool public stakingEnabled;

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

  constructor(address rewardTokenAddress_, uint256 rewardTokensPerBlock_, uint lockTime_, uint endBlock_) Ownable(msg.sender) {
    rewardTokensPerBlock = rewardTokensPerBlock_;
    stakeToken = IERC20(rewardTokenAddress_);
    lockedTime = lockTime_;
    endBlock = endBlock_;
    harvestLock = true;
  }

  modifier onlyPresale() {
    require(msg.sender == presaleContract, 'This method is only for presale Contract');
    _;
  }

  modifier onlyWithdrawEnabled() {
    require(withdrawEnabled, "Withdraw not enabled");
    _;
  }

  modifier onlyWhenStakingEnabled() {
    require(stakingEnabled, "Staking not enabled");
    _;
  }


  /**
   * @dev Stake tokens to the pool by presale contract
   */
  function depositByPresale(address user_, uint256 amount_) external onlyPresale onlyWhenStakingEnabled {
    require(block.number < endBlock, 'staking has been ended');
    require(amount_ > 0, "Deposit amount can't be zero");

    PoolStaker storage staker = poolStakers[user_];

    _harvestRewards(user_);

    staker.amount += amount_;
    staker.rewardDebt = (staker.amount * accumulatedRewardsPerShare) / REWARDS_PRECISION;
    staker.stakedTime = block.timestamp;
  
    tokensStaked += amount_;
    tokensStakedByPresale += amount_;

    emit Deposit(user_, amount_);
    stakeToken.safeTransferFrom(presaleContract, address(this), amount_);
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

  function setHarvestLock(bool harvestlock_) external onlyOwner {
    harvestLock = harvestlock_;
  }

  function setPresale(address presale_) external onlyOwner {
    presaleContract = presale_;
  }

  function setStakeToken(address stakeToken_) external onlyOwner {
    stakeToken = IERC20(stakeToken_);
  }

  function setLockedTime(uint time_) external onlyOwner {
    lockedTime = time_;
  }

  function setWithdrawEnabled(bool enabled_) external onlyOwner {
    withdrawEnabled = enabled_;
  }

  function setStakingEnabled(bool enabled_) external onlyOwner {
    stakingEnabled = enabled_;
  }

  function setEndBlock(uint endBlock_) external onlyOwner {
    endBlock = endBlock_;
  }
}