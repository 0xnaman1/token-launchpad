// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BancorBondingCurve} from "./utils/BancorBondingCurve.sol";
import {NewToken} from "./NewToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Errors} from "./utils/Errors.sol";

contract Launch is BancorBondingCurve {
    address public usdc;
    address public creator;

    uint256 public targetAmount;
    uint256 public reserveRatio;
    uint256 public tokensSold; // desired funding achieved when tokensSold >= 500M
    uint256 public fundsRaised;

    NewToken public newToken;
    IUniswapV2Router02 public uniswapRouter;
    bool public fundingSuccess;

    function initialize(
        address _usdcAddress,
        uint256 _targetAmount,
        string memory _name,
        string memory _symbol
    ) public {
        usdc = _usdcAddress;
        targetAmount = _targetAmount;
        tokensSold = 0;
        fundingSuccess = false;
        fundsRaised = 0;
        creator = msg.sender;
        newToken = new NewToken(_name, _symbol);

        uniswapRouter = IUniswapV2Router02(
            0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3
        );
    }

    function setInitialPrice(uint256 _usdcAmount) external {
        if (_usdcAmount <= 0) {
            revert Errors.ZeroAmt();
        }

        IERC20(usdc).transferFrom(msg.sender, address(this), _usdcAmount);

        uint256 denom = ((500_000_000 * _usdcAmount) / (1000_000_000));
        uint256 num = targetAmount;

        uint256 rr = num / denom;
        if (rr < 1) {
            rr = 1;
        }

        reserveRatio = rr;
    }

    function buy(uint256 _usdcAmount) public returns (uint256 tokensToMint) {
        if (_usdcAmount <= 0) {
            revert Errors.ZeroAmt();
        }

        if (fundingSuccess) {
            revert Errors.AlreadyFunded();
        }

        uint256 supply = newToken.totalSupply();

        uint256 reserveTokenBalance = IERC20(usdc).balanceOf(address(this));

        tokensToMint = calculatePurchaseReturn(
            supply,
            reserveTokenBalance,
            uint32(reserveRatio),
            _usdcAmount
        );

        tokensSold += tokensToMint;
        fundsRaised += _usdcAmount;
        IERC20(usdc).transferFrom(msg.sender, address(this), _usdcAmount);

        newToken.mint(msg.sender, tokensToMint);

        if (tokensSold >= 500_000_000 * 1e18) {
            postFunding();
        }
    }

    function sell(uint256 _sellAmount) public returns (uint256 usdcReturnAmt) {
        if (_sellAmount <= 0) {
            revert Errors.ZeroAmt();
        }

        if (fundingSuccess) {
            revert Errors.AlreadyFunded();
        }

        uint256 supply = newToken.totalSupply();
        uint256 reserveTokenBalance = IERC20(usdc).balanceOf(address(this));

        usdcReturnAmt = calculateSaleReturn(
            supply,
            reserveTokenBalance,
            uint32(reserveRatio),
            _sellAmount
        );

        tokensSold -= _sellAmount;
        fundsRaised -= usdcReturnAmt;
        newToken.transferFrom(msg.sender, address(this), _sellAmount);

        newToken.burn(_sellAmount);
        IERC20(usdc).transfer(msg.sender, usdcReturnAmt);
    }

    function postFunding() internal {
        if (fundingSuccess) {
            revert Errors.AlreadyFunded();
        }

        fundingSuccess = true;

        uint256 fundingRaised = fundsRaised;
        uint256 halfFunds = fundingRaised / 2;
        uint256 otherHalf = fundingRaised - halfFunds;

        newToken.transfer(creator, 200_000_000 * 1e18);
        IERC20(usdc).transfer(creator, halfFunds);

        // Other half of funds should be deployed to Uniswap
        newToken.approve(address(uniswapRouter), 250e6 * 1e18);
        IERC20(usdc).approve(address(uniswapRouter), otherHalf);

        uniswapRouter.addLiquidity(
            address(newToken),
            address(usdc),
            250e6 * 1e18,
            otherHalf,
            0,
            0,
            address(this),
            block.timestamp + 5 minutes
        );
    }
}
