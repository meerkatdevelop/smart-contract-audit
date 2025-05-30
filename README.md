# Meerkat project

## EVM Contracts

src/
 - MeerkatClaim.sol
 - MeerkatStaking.sol (staking when tokens would be live)
 - MeerkatToken.sol
 - Presale.sol (for Ethereum network)
 - PresaleL2.sol (for BSC and BASE networks)
 - Staking.sol (staking for presale tokens)

Deploy: forge script script/BASE/DeployPresaleL2Base.s.sol --rpc-url https://base.llamarpc.com --broadcast -vvvv --via-ir (https://base-mainnet.public.blastapi.io)
forge script script/BASE/DeployPresaleL2Base.s.sol --rpc-url https://binance.llamarpc.com --broadcast -vvvv --via-ir

## SOLANA Program

- lib.rs
