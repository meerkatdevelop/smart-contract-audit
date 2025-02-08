use anchor_lang::prelude::*;
use std::str::FromStr;
use anchor_lang::prelude::Pubkey;
use pyth_solana_receiver_sdk::price_update::{get_feed_id_from_hex, PriceUpdateV2};


declare_id!("AszSDxnpJW3GWPMuRfyQCvoJiz1U6E6fHCbVemnV9vD2");

pub const LAMPORTS_PER_SOL: u64 = 1_000_000_000;
pub const MAXIMUM_AGE: u64 = 60; // One minute
pub const FEED_ID: &str = "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d"; // SOL/USD price feed id from https://pyth.network/developers/price-feed-ids


#[program]
pub mod meerkat_presale_sol {
    use super::*;

    /// # Behavior
    /// Initializes the Meerkat presale with the owner and receiver addresses, the phase and the status of the presale.
    /// The owner is the address that can manage the presale, and the receiver is the address that will receive the funds.
    /// The owner must be the trusted owner, which is a hardcoded address.
    /// The receiver must be a valid address.
    /// The presale can only be initialized once.
    /// # Arguments
    ///  `ctx` - The context of the program.
    /// # Errors
    /// The function will return an error if: 
    /// - The owner is not the trusted owner.
    /// - The receiver address is not valid.
    /// - The meerkat presale account is not owned by the correct program.
    /// - The presale is already initialized.
    /// # Access Control
    /// The function can only be called by the owner.


    pub fn init_presale(ctx: Context<InitPresale>) -> Result<()> {
        msg!("MESSAGE: Init Meerkat presale...");
        let pubkey_str = "7YXPj2a1nUDbCeMcVkrHMbwmsTwjNpM5VXPDBkeFEJsb";
        let trusted_owner_pubkey = Pubkey::from_str(pubkey_str).unwrap();
        let zero_pubkey = Pubkey::default();
        // MeerkatPresale is generated derived from the program ID (Similar to the smart contract address)
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;
        let presale_owner = ctx.accounts.presale_owner.key();

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the MeerkatPresale account is not already initialized
        if meerkat_presale.presale_owner != zero_pubkey {
            msg!("ERROR: Meerkat presale is already initialized.");
            return Err(MeerkatPresaleErrorsCode::PresaleAlreadyInitialized.into());
        }

        if presale_owner != trusted_owner_pubkey {
            msg!("ERROR: The owner is not the trusted owner.");
            return Err(MeerkatPresaleErrorsCode::IncorrectOwner.into());
        }

    //  Ensure the receiver is a valid Solana system account (avoids redirecting funds) and it is not executable
        if ctx.accounts.receiver.owner != &System::id() || ctx.accounts.receiver.executable {
            msg!("ERROR: The receiver account is not a valid System account.");
            return Err(MeerkatPresaleErrorsCode::InvalidReceiverAddress.into());
        }
            meerkat_presale.presale_owner = presale_owner;
            meerkat_presale.receiver = ctx.accounts.receiver.key();
            meerkat_presale.paused = false;
            meerkat_presale.phase = 0;
            meerkat_presale.phase_prices = [0.0005, 0.0015, 0.003];
            meerkat_presale.max_tokens = [1000000, 2000000, 3000000];
            meerkat_presale.tokens_sold = [0.0, 0.0, 0.0];


        msg!("MESSAGE: End meerkat_presale initialization...");

        Ok(())
    }

    /// # Behavior
    /// Allows users to buy tokens with SOL.
    /// The user must send the correct amount of SOL to the receiver address.
    /// The receiver address is the treasury wallet that will receive the funds.
    /// The user must send the correct amount of SOL to the receiver address.
    /// The function will emit an event with the payer, receiver, eth_address, amount, and timestamp.
    ///  # Arguments
    /// `ctx` - The context of the program.
    /// `metadata` - Extra information with the SOL quantity.
    /// # Errors
    /// The function will return an error if:
    /// - The receiver address is not valid.
    /// - The payer account does not have enough funds.


    pub fn buy_with_sol(ctx: Context<BuyWithSol>, metadata: TokenParams) -> Result<()> {
        msg!("MESSAGE: Starting buy_with_sol function.");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the presale is not paused
        if meerkat_presale.paused {
            msg!("ERROR: The presale is paused.");
            return Err(MeerkatPresaleErrorsCode::PresaleAlreadyPaused.into());
        }

        let expected_receiver: Pubkey = meerkat_presale.receiver;

        let receiver: Pubkey = ctx.accounts.receiver.key();
        if receiver != expected_receiver {
            msg!("ERROR: The receiver address is not valid.");
            return Err(error!(MeerkatPresaleErrorsCode::IncorrectReceiver));
        }

        let sol_amount_lamports = metadata.quantity as u64;

        let payer: Pubkey = ctx.accounts.payer.key();
        let payer_balance = ctx.accounts.payer.to_account_info().lamports();
        if payer_balance < sol_amount_lamports {
            return Err(error!(MeerkatPresaleErrorsCode::InsufficientFunds));
        }


        // Get the current timestamp from the Sysvar::Clock
        let clock = &ctx.accounts.clock;
        let timestamp = clock.unix_timestamp; // This is in seconds since Unix epoch

        let price_update = &mut ctx.accounts.price_update;
        let price = price_update.get_price_no_older_than(
            &Clock::get()?,
            MAXIMUM_AGE,
            &get_feed_id_from_hex(FEED_ID)?,
        )?;
        let price_value = price.price as u64;
        let price_conf= price.conf;
        let price_exponent = price.exponent;
        let price_usd = price_value as f64 * 10f64.powi(price_exponent);
        let sol = sol_amount_lamports as f64 / LAMPORTS_PER_SOL as f64;
        let usd_value = sol as f64  * price_usd as f64 ;

        let phase = meerkat_presale.phase as usize;
        let price_phase = meerkat_presale.phase_prices[phase] as f64;
        let tokens = usd_value / price_phase as f64;
        let total_tokens_sold = meerkat_presale.tokens_sold[phase] as f64;
        let tokens_left = meerkat_presale.max_tokens[phase] as f64 - total_tokens_sold;
        if  tokens > tokens_left {
            msg!("ERROR: The user is trying to buy more tokens than available.");
            return Err(error!(MeerkatPresaleErrorsCode::InsufficientFunds));
        }
        meerkat_presale.tokens_sold[phase] = total_tokens_sold + tokens;
        let purchase_ix = solana_program::system_instruction::transfer(
            &payer,   // user buyer
            &receiver,  // treasury wallet
            sol_amount_lamports as u64,
        );


        solana_program::program::invoke(
            &purchase_ix,
            &[
                ctx.accounts.payer.to_account_info(),
                ctx.accounts.receiver.to_account_info(),
                ctx.accounts.system_program.to_account_info(),
            ],
        )?;

        msg!("MESSAGE: End buy_with_sol function.");
        msg!("VERIFIED_EVENT: Payer ={}, Receiver ={}, Eth Address ={}, Amount ={}, Timestamp ={}, price ={}, exponent ={}, phase ={}, tokens ={}, total_tokens_sold ={}", payer, receiver, metadata.address_eth_account, sol_amount_lamports, timestamp, price_value,  price_exponent, phase, tokens, meerkat_presale.tokens_sold[phase]);

            Ok(())
    }

  

    pub fn pause_presale(ctx: Context<PausePresale>) -> Result<()> {
        msg!("MESSAGE: Pausing the presale...");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the owner is the correct presale owner
        check_is_presale_owner(&ctx.accounts.presale_owner.key(), &meerkat_presale.presale_owner)?;

        // Ensure the presale is not already paused
        if meerkat_presale.paused {
            msg!("ERROR: Presale is already paused.");
            return Err(MeerkatPresaleErrorsCode::PresaleAlreadyPaused.into());
        }
        meerkat_presale.paused = true;
        msg!("MESSAGE: Presale is paused");
        Ok(())
    }

    pub fn unpause_presale(ctx: Context<UnPausePresale>) -> Result<()> {
        msg!("MESSAGE: UnPausing the presale...");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the owner is the correct presale owner
        check_is_presale_owner(&ctx.accounts.presale_owner.key(), &meerkat_presale.presale_owner)?;

        // Ensure the presale is not already paused
        if !meerkat_presale.paused {
            msg!("ERROR: Presale is not paused.");
            return Err(MeerkatPresaleErrorsCode::PresaleAlreadyPaused.into());
        }

        meerkat_presale.paused = false;
        msg!("MESSAGE: Presale is paused");
        Ok(())
    }

    pub fn update_phase(ctx: Context<UpdatePhase>, new_phase: u8) -> Result<()> {
        msg!("MESSAGE: Updating phase...");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the owner is the correct presale owner
        check_is_presale_owner(&ctx.accounts.presale_owner.key(), &meerkat_presale.presale_owner)?;

        // Ensure the phase is valid
        check_phase(new_phase)?;

        meerkat_presale.phase = new_phase;
        msg!("MESSAGE: Presale phase is updated to {}", new_phase);
        Ok(())
    }

    pub fn update_prices(ctx: Context<UpdatePrices>, new_price: f64,  phase: u8) -> Result<()> {
        msg!("MESSAGE: Updating price...");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the owner is the correct presale owner
        check_is_presale_owner(&ctx.accounts.presale_owner.key(), &meerkat_presale.presale_owner)?;

        // Ensure the phase is valid
        check_phase(phase)?;

        meerkat_presale.phase_prices[phase as usize] = new_price;
        msg!("MESSAGE: Presale prices are updated to");
        Ok(())
    }

    pub fn update_max_tokens(ctx: Context<UpdateMaxTokens>, new_max_token: u64, phase: u8) -> Result<()> {
        msg!("MESSAGE: Updating max tokens...");
        let meerkat_presale = &mut ctx.accounts.meerkat_presale;

        // Ensure the MeerkatPresale account is owned by the correct program
        check_meerkat_presale_account_owner(&meerkat_presale.to_account_info(), &ctx.program_id)?;

        // Ensure the owner is the correct presale owner
        check_is_presale_owner(&ctx.accounts.presale_owner.key(), &meerkat_presale.presale_owner)?;

        // Ensure the phase is valid
        check_phase(phase)?;

        // Update the correct phase
        meerkat_presale.max_tokens[phase as usize] = new_max_token;
        msg!("MESSAGE: Presale max tokens are updated");
        Ok(())
    }
}

//** HELPER FUNCTIONS **//

// Check if the phase is valid
fn check_phase(phase: u8) -> Result<()> {
    if phase > 2 {
        msg!("ERROR: The phase is not valid.");
        return Err(MeerkatPresaleErrorsCode::PhaseOutOfRange.into());
    }
    Ok(())
}

// Check if the account (meerkat_presale_account) owner is the Program ID
fn check_meerkat_presale_account_owner(account: &AccountInfo, expected_owner: &Pubkey,) -> Result<()> {
    if account.owner != expected_owner {
        msg!("ERROR: The account owner is incorrect. Expected program ID is not the owner.");
        return Err(MeerkatPresaleErrorsCode::IncorrectAccountOwner.into());
    }
    Ok(())
}

// Check if the owner is the trusted presale-owner
fn check_is_presale_owner(actual_owner: &Pubkey, presale_owner: &Pubkey) -> Result<()> {
    if actual_owner != presale_owner {
        msg!("ERROR: The owner is not the trusted owner.");
        return Err(MeerkatPresaleErrorsCode::IncorrectOwner.into());
    }
    Ok(())
}

//** ACCOUNTS **//
#[account]
pub struct MeerkatPresale {
  /// The public key of the owner, who can manage the presale.
    pub presale_owner: Pubkey,

    /// The public key of the receiver, who will receive the funds. It is a treasury wallet.
    pub receiver: Pubkey,

    /// Shows if presale is paused or not.
    pub paused: bool,

    /// The phase of the presale(0/1/2)
    pub phase: u8,

    pub phase_prices: [f64; 3],

    pub max_tokens: [u64; 3],

    pub tokens_sold: [f64; 3],
}

//** FUNCTION CONTEXTS **//

#[derive(Accounts)]
pub struct InitPresale<'info> {
  #[account(
    init,
    payer = presale_owner,
    seeds = [b"meerkat_presale"],
    bump,
    space = 8 + 32 + 4 + (32 * 300)
)]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub receiver: AccountInfo<'info>,
    pub system_program: Program<'info, System>
}

#[derive(Accounts)]
pub struct BuyWithSol<'info> {
  #[account(
    mut,
    seeds = [b"meerkat_presale"],
    bump,
    )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(mut)]
    pub receiver: AccountInfo<'info>,
    pub price_update: Account<'info, PriceUpdateV2>,
    pub system_program: AccountInfo<'info>,
    pub rent: Sysvar<'info, Rent>,
    pub clock: Sysvar<'info, Clock>
}

#[derive(Accounts)]
pub struct PausePresale<'info> {
    #[account(
        mut,
        seeds = [b"meerkat_presale"],
        bump,
        has_one = presale_owner,
        )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UnPausePresale<'info> {
    #[account(
        mut,
        seeds = [b"meerkat_presale"],
        bump,
        has_one = presale_owner,
        )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}


#[derive(Accounts)]
pub struct UpdatePhase<'info> {
    #[account(
        mut,
        seeds = [b"meerkat_presale"],
        bump,
        has_one = presale_owner,
        )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct UpdatePrices<'info> {
    #[account(
        mut,
        seeds = [b"meerkat_presale"],
        bump,
        has_one = presale_owner,
        )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct UpdateMaxTokens<'info> {
    #[account(
        mut,
        seeds = [b"meerkat_presale"],
        bump,
        has_one = presale_owner,
        )]
    pub meerkat_presale: Account<'info, MeerkatPresale>,
    #[account(mut)]
    pub presale_owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

//** DATA **//

#[derive(AnchorSerialize, AnchorDeserialize, Debug, Clone)]
pub struct TokenParams {
    pub address_eth_account: String,
    pub quantity: u64,
}


//** ERROR CODES **//

#[error_code]
pub enum MeerkatPresaleErrorsCode {
    #[msg("The receiver address is incorrect.")]
    IncorrectReceiver,
    #[msg("The receiver address is invalid.")]
    InvalidReceiverAddress,
    #[msg("The payer account does not have enough funds.")]
    InsufficientFunds,
    #[msg("Meerkat presale is already initialized.")]
    PresaleAlreadyInitialized,
    #[msg("The owner is not the trusted owner.")]
    IncorrectOwner,
    #[msg("The presale is already paused.")]
    PresaleAlreadyPaused,
    #[msg("The account owner is incorrect. The program ID is not the owner.")]
    IncorrectAccountOwner,
    #[msg("The phase is not valid.")]
    PhaseOutOfRange,
}
