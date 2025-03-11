Below is the `.md` file that provides an overview of your project and its features. It includes a description of the project, its purpose, and the functionality of each contract.

---

# Decentralized Exchange (DEX) Project Overview

## Table of Contents
- [Decentralized Exchange (DEX) Project Overview](#decentralized-exchange-dex-project-overview)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Project Features](#project-features)
  - [Contracts Overview](#contracts-overview)
    - [ODex.sol](#odexsol)
      - [Key Features:](#key-features)
      - [Functions:](#functions)
    - [LPToken.sol](#lptokensol)
      - [Key Features:](#key-features-1)
      - [Functions:](#functions-1)
    - [TokenA.sol and TokenB.sol](#tokenasol-and-tokenbsol)
      - [Key Features:](#key-features-2)
      - [Functions:](#functions-2)
  - [Testing Environment](#testing-environment)

---

## Introduction

This project is a **Decentralized Exchange (DEX)** built using Solidity and deployed on the Ethereum blockchain. The DEX allows users to create liquidity pools, add/remove liquidity, and swap tokens in a decentralized manner. It leverages the **Automated Market Maker (AMM)** model, where liquidity providers deposit token pairs into pools, and traders can swap tokens based on the pool's reserves.

The project was developed using the **Foundry framework** and tested on **Remix IDE** for ease of deployment and interaction.

---

## Project Features

- **Liquidity Pool Creation**: Users can create liquidity pools by depositing equal value of two tokens.
- **Add/Remove Liquidity**: Liquidity providers can add or remove liquidity from existing pools, earning proportional shares of trading fees.
- **Token Swapping**: Users can swap one token for another within a liquidity pool, with slippage protection.
- **Reentrancy Protection**: All critical functions are protected against reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.
- **LP Token Management**: Liquidity providers receive LP tokens representing their share of the pool, which can be burned to withdraw liquidity.
- **Spot Price Calculation**: The DEX calculates the spot price of tokens in a pool based on their reserves.

---

## Contracts Overview

### ODex.sol

The core contract of the DEX, responsible for managing liquidity pools and facilitating token swaps.

#### Key Features:
- **Pool Management**:
  - Users can create liquidity pools by depositing two tokens.
  - Liquidity providers can add or remove liquidity from existing pools.
- **Token Swapping**:
  - Implements the AMM formula:  
    \[
    \text{outputAmount} = \frac{\text{outputReserve} \times \text{inputAmount}}{\text{inputReserve} + \text{inputAmount}}
    \]
  - Includes a 0.3% fee on swaps, which is distributed to liquidity providers.
- **Reentrancy Protection**:
  - Uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
- **Modifiers**:
  - `validTokenAddresses`: Ensures token addresses are valid and distinct.
  - `hasBalanceAndAllowance`: Checks if the user has sufficient balance and allowance for token transfers.
  - `poolMustExist`: Ensures the pool exists before performing operations.

#### Functions:
- `createPool`: Creates a new liquidity pool with initial deposits.
- `addLiquidity`: Adds liquidity to an existing pool.
- `removeLiquidity`: Removes liquidity from a pool and burns LP tokens.
- `swap`: Allows users to swap tokens within a pool.
- `getSpotPrice`: Calculates the current spot price of a token pair in a pool.

---

### LPToken.sol

The LP token contract represents liquidity providers' shares in a pool. It inherits from OpenZeppelin's `ERC20` standard.

#### Key Features:
- **Minting and Burning**:
  - Liquidity providers receive LP tokens when they add liquidity.
  - LP tokens are burned when liquidity is removed.
- **Access Control**:
  - Only the DEX contract can mint or burn LP tokens.
  - The owner can set the DEX address once during initialization.

#### Functions:
- `mint`: Mints new LP tokens to a specified address.
- `burn`: Burns LP tokens from a specified address.
- `setDexAddress`: Sets the DEX contract address (can only be called by the owner).

---

### TokenA.sol and TokenB.sol

These are ERC20 token contracts used for testing the DEX. They represent the tokens being traded in the liquidity pools.

#### Key Features:
- **Standard ERC20 Implementation**:
  - Implements the OpenZeppelin `ERC20` standard.
- **Owner-Controlled Minting**:
  - Only the owner can mint new tokens.

#### Functions:
- `mint`: Mints new tokens to a specified address (only callable by the owner).

---

## Testing Environment

The project was tested using the following tools:

- **Remix IDE**: Used for manual testing and interaction with the deployed contracts.

Testing included:
- Creating liquidity pools and verifying token balances.
- Adding and removing liquidity to ensure correct LP token distribution.
- Swapping tokens and verifying output amounts with slippage protection.
- Ensuring reentrancy protection works as expected.



This `.md` file provides a comprehensive overview of your project, highlighting its features, functionality, and future potential. It serves as a useful reference for developers and stakeholders involved in the project.