//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/LiadexLiquidityToken.sol";
import "src/SafeMath.sol";
import "src/ITradingPair.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/*
    This contract is automated-market-maker based liquidity pool that can be initialized via constructor
    on any two distinct ERC20-token contracts and lets users add liquidity to the pool, remove it, or swap
    one of the two ERC20s for the other. Anyone intending to use this code should first make sure they
    understand all implemented contracts, interfaces and libraries and the following code itself.
*/
contract TradingPair is LiadexLiquidityToken, ITradingPair, ReentrancyGuard {

    event Swap(address tokenSwapped, address tokenObtained, uint256 amountSwapped, uint256 amountObtained);
    event LiquidityAdded(uint256 amountA, uint256 amountB);
    event LiquidityWithdrawn(uint256 amountA, uint256 amountB);

    using SafeMath for uint256;

    address public immutable _tokenA;
    address public immutable _tokenB;
    uint256 private _reserveA = 0;
    uint256 private _reserveB = 0;
    uint256 private _k; //this value represents the ratio between the two token reserves

    uint256 public constant _feeNumerator = 5;
    uint256 public constant _feeDenominator = 1000;

    /*
    constructor takes as arguments two distinct ERC20 contract addresses, which one is tokenA
    or tokenB makes no difference at all, it's just for distinction
    */
    constructor (address tokenA, address tokenB) {
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    function getK() public view returns (uint256) {
        return _k;
    }

    function getTokenA() public view returns (address) {
        return _tokenA;
    }

    function getTokenB() public view returns (address) {
        return _tokenB;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (_reserveA, _reserveB);
    }

    function getBalances() public view returns (uint256, uint256) {
        return (IERC20(_tokenA).balanceOf(address(this)), IERC20(_tokenB).balanceOf(address(this)));
    }

    /*
    The following function lets users provide liquidity to the trading-pair-related liquidity pool,
    the token amount arguments have to be of equal value for the liquidity provision to be successful
    */
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        require (amountA > 0 && amountB > 0, "Deposit amounts can't be 0.");

        /*
        The following if statement handles the first liquidity provision of the liquidity pool
        */
        if (totalSupply() == 0) {
            
            IERC20(_tokenA).transferFrom(address(msg.sender), address(this), amountA);
            IERC20(_tokenB).transferFrom(address(msg.sender), address(this), amountB);

            mint(address(msg.sender), initializationAmount);
            emit LiquidityAdded(amountA, amountB);
        }

        else {
            bool equalValue = amountA * _reserveB / _reserveA == amountB;
            require(equalValue, "Token amounts provided are not of equal value."); //require that token amounts are of the same value
            
            IERC20(_tokenA).transferFrom(address(msg.sender), address(this), amountA);
            IERC20(_tokenB).transferFrom(address(msg.sender), address(this), amountB);
            uint256 liquidityTokenToMint = amountA.mul(totalSupply()).div(_reserveA);
            mint(address(msg.sender), liquidityTokenToMint);
            emit LiquidityAdded(amountA, amountB);
        }

        sync();
    }

    /*
    The following function lets users withdraw liquidity from the trading-pair-related liquidity pool,
    the token amount arguments have to be of equal value for the liquidity withdrawal to be successful
    */
    function withdraw(uint256 amountA, uint256 amountB) external nonReentrant {

        require (amountA > 0 && amountB > 0, "Withdraw amounts can't be 0.");

        bool equalValue = amountA * _reserveB / _reserveA == amountB;
        require(equalValue, "Token withdraw amounts are not of equal value."); //require that token amounts are of the same value

        uint256 liquidityTokenToBurn = amountA.mul(totalSupply()).div(_reserveA);
        require(balanceOf(address(msg.sender)) >= liquidityTokenToBurn, "User doesn't own enough liquidity pool funds.");

        IERC20(_tokenA).transfer(address(msg.sender), amountA);
        IERC20(_tokenB).transfer(address(msg.sender), amountB);

        burn(address(msg.sender), liquidityTokenToBurn);

        emit LiquidityWithdrawn(amountA, amountB);

        sync();
    }

    /*
    This is the function that lets users swap one of the liquidity pool's assets for the other. The argument
    amount greater than zero is the token that the user is giving to the pool. The function then calculates its
    value and sends to the user an amount of the other token that's of equal value as the token the user sent.
    */
    function swap(uint256 tokenAAmount, uint256 tokenBAmount) external nonReentrant {
        require (tokenAAmount > 0 ? tokenBAmount == 0 : tokenBAmount > 0, "Swap failed.");
        uint256 amountInWithFee;
        uint256 newReserveOut;
        uint256 amountOut;
        if (tokenAAmount > 0) {
            amountInWithFee = tokenAAmount * (_feeDenominator - _feeNumerator) / _feeDenominator;
            newReserveOut = _reserveA * _reserveB / (_reserveA + amountInWithFee);
            amountOut = _reserveB - newReserveOut;
            require(amountOut < _reserveB, "Not enough reserves.");
            bool success = IERC20(_tokenA).transferFrom(address(msg.sender), address(this), tokenAAmount);
            require(success, "Swap failed.");
            IERC20(_tokenB).transfer(address(msg.sender), amountOut);
            sync();
            emit Swap(_tokenA, _tokenB, tokenAAmount, amountOut);
        }
        if (tokenBAmount > 0) {
            amountInWithFee = tokenBAmount * (_feeDenominator - _feeNumerator) / _feeDenominator;
            newReserveOut = _reserveA * _reserveB / (_reserveB + amountInWithFee);
            amountOut = _reserveA - newReserveOut;
            require(amountOut < _reserveA, "Not enough reserves.");
            bool success = IERC20(_tokenB).transferFrom(address(msg.sender), address(this), tokenBAmount);
            require(success, "Swap failed.");
            IERC20(_tokenA).transfer(address(msg.sender), amountOut);
            sync();
            emit Swap(_tokenB, _tokenA, tokenBAmount, amountOut);
        }
    }

    function sync() private {
        uint256 a = IERC20(_tokenA).balanceOf(address(this));
        uint256 b = IERC20(_tokenB).balanceOf(address(this));
        _reserveA = a;
        _reserveB = b;
        _k = a.mul(b);
    }
}