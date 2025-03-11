// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Presale} from "../src/Presale.sol";
import {Staking} from "../src/Staking.sol";
import {MeerkatToken} from "../src/MeerkatToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/Test.sol";

contract DeployPresale is Script {
    using SafeERC20 for IERC20;
    
    address deployer = vm.addr(1);  // @audit CAMBIAR A FINAL

    // MeerkatToken
    MeerkatToken meerkatToken;
    address meerkatTokenAddress; 

    // Presale
    Presale presale;
    address usdtAddress_ = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // @audit CAMBIAR A FINAL
    address usdcAddress_ = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // @audit CAMBIAR A FINAL
    address aggregatorContract_ = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // @audit CAMBIAR A FINAL
    address stakingContract= vm.addr(3); // @audit CAMBIAR A FINAL
    address paymentWallet_ = vm.addr(2); // @audit CAMBIAR A FINAL
    uint256[][3] phases_; 
    uint256 maxTotalSellingAmount_ = 10000000000000 * 1e18;  // @audit CAMBIAR A FINAL
    uint256 usdLimitPhase0_ = 1000000 * 1e18; // @audit CAMBIAR A FINAL
    uint256 usdLimitPhase1_ = 1000000 * 1e18; // @audit CAMBIAR A FINAL


    // Staking
    Staking staking;
    address rewardTokenAddress_;
    address presaleContract_;
    uint256 rewardTokensPerBlock_ = 304 * 10^18; // @audit CAMBIAR A FINAL
    uint lockTime_ = 604800; // @audit CAMBIAR A FINAL
    uint endBlock_ = block.timestamp + 30 days; // @audit CAMBIAR A FINAL


    function run() external returns (Presale) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Meerkat Token
        meerkatToken = new MeerkatToken(deployer);
        meerkatTokenAddress = address(meerkatToken);

        // Deploy Staking
        rewardTokenAddress_ = meerkatTokenAddress;
        staking = new Staking(rewardTokenAddress_, rewardTokensPerBlock_, lockTime_, endBlock_);

        // Deploy Presale
        stakingContract = address(staking);
        phases_[0] = [200_000_000 * 10**18, 5000, 2737897226]; // @audit CAMBIAR A FINAL
        phases_[1] = [700_000_000 * 10**18, 15000, 2737997226]; // @audit CAMBIAR A FINAL
        phases_[2] = [700_000_000 * 10**18, 30000, 2738897226]; // @audit CAMBIAR A FINAL
        presale = new Presale(meerkatTokenAddress, usdtAddress_, usdcAddress_, aggregatorContract_, stakingContract, paymentWallet_, phases_, maxTotalSellingAmount_, usdLimitPhase0_, usdLimitPhase1_);
        
        uint256 balanceOfMeerkat = IERC20(meerkatToken).balanceOf(deployer); // @audit CAMBIAR A FINAL
        IERC20(meerkatToken).transfer(address(presale), balanceOfMeerkat); // @audit CAMBIAR A FINAL
        presaleContract_ = address(presale);

        staking.setPresale(address(presale));


        vm.stopBroadcast();
        return presale;
    }
}