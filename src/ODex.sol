// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface ILPToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract ODex is ReentrancyGuard {
    mapping(bytes => Pool) pools;
    uint INITIAL_LP_BALANCE = 10_000 * 1e18;
    uint LP_FEE = 30;
    ILPToken public lpToken;
     address public owner;

    struct Pool {
        mapping(address => uint) tokenBalances;
        mapping(address => uint) lpBalances;
        uint totalLpTokens;
    }
    constructor(
        address LPtokenAddress
    ) {
        lpToken = ILPToken(LPtokenAddress);
        owner = msg.sender;
    }
    /**
     * @custom:dev-run-script run-dev-tests
     */

    function createPool(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    )
        public
        validTokenAddresses(tokenA, tokenB)
        hasBalanceAndAllowance(tokenA, tokenB, amountA, amountB)
        nonReentrant
    {
        // check all values are valid
        Pool storage pool = _getPool(tokenA, tokenB);
        require(pool.tokenBalances[tokenA] == 0, "pool already exists");

        // deposit tokens into contract
        _transferToken(tokenA, tokenB, amountA, amountB);

        // initialize the pool
        pool.tokenBalances[tokenA] = amountA;
        pool.tokenBalances[tokenB] = amountB;
        pool.lpBalances[msg.sender] = INITIAL_LP_BALANCE;

        // Dex contract transfers LP tokens to Pool creator
        lpToken.mint(msg.sender, INITIAL_LP_BALANCE);
        
        pool.totalLpTokens = INITIAL_LP_BALANCE;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    )
        public
        validTokenAddresses(tokenA, tokenB)
        hasBalanceAndAllowance(tokenA, tokenB, amountA, amountB)
        poolMustExist(tokenA, tokenB)
        nonReentrant
    {
        Pool storage pool = _getPool(tokenA, tokenB);
        uint tokenAPrice = getSpotPrice(tokenA, tokenB);
        require(
            tokenAPrice * amountA == amountB * 1e18,
            "must add liquidity at the current spot price"
        );

        _transferToken(tokenA, tokenB, amountA, amountB);

        uint newTokens = (amountA * INITIAL_LP_BALANCE) / pool.tokenBalances[tokenA];

        pool.tokenBalances[tokenA] += amountA;
        pool.tokenBalances[tokenB] += amountB;
        pool.totalLpTokens += newTokens;
        pool.lpBalances[msg.sender] += newTokens;

        lpToken.mint(msg.sender, newTokens);
    }

    function removeLiquidity(address tokenA, address tokenB)
        public
        validTokenAddresses(tokenA, tokenB) 
        poolMustExist(tokenA, tokenB)
        nonReentrant
    {
        // to check if the pool has some liquidity
        Pool storage pool = _getPool(tokenA, tokenB);
        uint balance = pool.lpBalances[msg.sender];
        require(balance > 0, "No liquidity provided by this user");

        // how much of tokenA and tokenB should we send to the LP?
        // if a user has 10% of the pool, he will recieve 10% of tokenA and 10% of tokenB

        uint tokenAAmount = (balance * pool.tokenBalances[tokenA]) / pool.totalLpTokens;
        uint tokenBAmount = (balance * pool.tokenBalances[tokenB]) / pool.totalLpTokens;

        pool.lpBalances[msg.sender] = 0;
        pool.tokenBalances[tokenA] -= tokenAAmount;
        pool.tokenBalances[tokenB] -= tokenBAmount;
        pool.totalLpTokens -= balance;

        // send tokens to user
        ERC20 contractA = ERC20(tokenA);
        ERC20 contractB = ERC20(tokenB);

        require(contractA.transfer(msg.sender, tokenAAmount), "transfer failed");
        require(contractB.transfer(msg.sender, tokenBAmount), "transfer failed");
        lpToken.burn(msg.sender, balance);
    }

    function swap(address from, address to, uint amount,uint minOutputAmount)
        public
        validTokenAddresses(from, to) 
        poolMustExist(from, to)
        nonReentrant    
    {
        Pool storage pool = _getPool(from, to);

        // deltaY = y * r * deltaX / x + (r * deltaX)
        // outputAmount = (outputReserve * inputAmount) / (inputReserve + inputAmount)
        
        amount = (amount * 997) / 1000;
        uint outputTokens = pool.tokenBalances[to] * amount / (pool.tokenBalances[to] + amount);        
        
        // check out for slippage 
        require(outputTokens >= minOutputAmount, "Slippage exceeded");

        pool.tokenBalances[from] += amount;
        pool.tokenBalances[to] -= outputTokens;

        ERC20 contractFrom = ERC20(from);
        ERC20 contractTo = ERC20(to);

        require(contractFrom.transferFrom(msg.sender, address(this), amount), "transfer failed");
        require(contractTo.transfer(msg.sender, outputTokens), "transfer failed");
    }

    // helpers
    function _getPool(
        address tokenA,
        address tokenB
    ) view internal returns (Pool storage pool) {
        bytes memory key;
        if (tokenA < tokenB) {
            key = abi.encodePacked(tokenA, tokenB);
        } else {
            key = abi.encodePacked(tokenB, tokenA);
        }
        return pools[key];
    }

    function _transferToken(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) internal {
        ERC20 contractA = ERC20(tokenA);
        ERC20 contractB = ERC20(tokenB);

        require(
            contractA.transferFrom(msg.sender, address(this), amountA),
            "Transfer of TokenA failed"
        );
        require(
            contractB.transferFrom(msg.sender, address(this), amountB),
            "Transfer of TokenB failed"
        );
    }

    function getSpotPrice(address tokenA, address tokenB) public view returns (uint) {
        Pool storage pool = _getPool(tokenA, tokenB);
        require(
            pool.tokenBalances[tokenA] > 0 && pool.tokenBalances[tokenB] > 0,
            "balances must be non-zero"
        );
        return ((pool.tokenBalances[tokenB] * 1e18) /
            pool.tokenBalances[tokenA]);
    }

    // Modifiers
    modifier validTokenAddresses(address tokenA, address tokenB) {
        require(tokenA != tokenB, "addresses must be different!");
        require(
            tokenA != address(0) && tokenB != address(0),
            "must be valid address"
        );
        _;
    }

    modifier hasBalanceAndAllowance(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) {
        ERC20 contractA = ERC20(tokenA);
        ERC20 contractB = ERC20(tokenB);

        // Check if the user has enough balance for TokenA
        require(
            contractA.balanceOf(msg.sender) >= amountA,
            "User doesn't have enough balance for TokenA"
        );

        // Check if the user has enough balance for TokenB
        require(
            contractB.balanceOf(msg.sender) >= amountB,
            "User doesn't have enough balance for TokenB"
        );
        require(
            contractA.allowance(msg.sender, address(this)) >= amountA,
            "user didn't grant allowance for A"
        );
        require(
            contractB.allowance(msg.sender, address(this)) >= amountB,
            "user didn't grant allowance for B"
        );

        _;
    }

    modifier poolMustExist(address tokenA, address tokenB) {
        Pool storage pool = _getPool(tokenA, tokenB);
        require(pool.tokenBalances[tokenA] != 0, "pool must exist");
        require(pool.tokenBalances[tokenB] != 0, "pool must exist");
        _;
    }
}
