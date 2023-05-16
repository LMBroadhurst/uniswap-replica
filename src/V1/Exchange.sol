// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
  function getExchange(address _tokenAddress) external returns (address);
}

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}

contract Exchange is ERC20 {

    // Public variables
    address public tokenAddress;
    address public factoryAddress;


    // uint256 public totalSupply; // defined in IERC20
    mapping(address userLuniAddress => uint256 userLuniBalance) balances;
    mapping(address userAddress => mapping(address approvedAddress => uint256 amount)) allowances;

    // Events
    event TokenPurchase(address indexed buyer, uint256 indexed ethSold, uint256 indexed tokensBought);
    event EthPurchase(address indexed buyer, uint256 indexed tokensSold, uint256 indexed ethBought);
    event AddLiquidity(address indexed provider, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event RemoveLiquidity(address indexed buyer, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event Transfer(address indexed buyer, uint256 indexed _to, uint256 indexed _value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 indexed _value); // defined in IERC20
    event MintLuni(address indexed _minter, uint256 indexed _amount);

    // @notice All Exchange contracts will use the LuniSwap V1 / LUNI-V1 name / ticker.
    // @param _tokenAddress: The token to be used in the pool against ETH.
    constructor(address _tokenAddress) ERC20("LuniSwap V1", "LUNI-V1") {
        require(_tokenAddress != address(0), "Token address cannot be 0");
        
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;
    }

    // -- LIQUIDITY IN/OUT -- //

    // @dev Allows users to add liquidity to an established pool, or create a new pool if one doesn't exist
    // @param _tokenAmount: Should be equal to the ratio of _token <-> ETH on the public market.
    function addLiquidity(uint256 _minLiquidity, uint256 _maxTokens, uint256 _deadline)
    public payable returns (uint256) {

        // input validation checks.
        require(_deadline > block.timestamp &&
                _maxTokens > 0 &&
                msg.value > 0, "Error with inputs"
        );

        if (totalSupply() > 0) {

            require(_minLiquidity > 0, "_minLiquidity must be greater than 0.");

            // Need to - msg.value from balance as the function has already taken the msg.balance from payable
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getTokenReserves();

            // calculate tokens needed for swap and LUNI minted
            // +1 to ethReserve confused me initially. It looks like it's to avoid a 0 division error by making it at least 1 wei
            uint256 tokenAmount = (msg.value * tokenReserve) / (ethReserve + 1);
            uint256 liquidityMinted = (msg.value * totalSupply()) / ethReserve;

            // ensures that there has not been a miscalculation or incorrect tokenAmount input
            require(_maxTokens >= tokenAmount, "x");

            // Ensures we are getting at least the min expected liquidity
            // If there is major slippage induced between time UI is clicked and transaction is processed, transaction
            // won't be processed.
            require(liquidityMinted >= _minLiquidity, "insufficient token amount");

            // update liquidity pool state
            balances[msg.sender] += liquidityMinted;

            // Approve token transfer, transfer tokens from msg.sender to pool, if successful mint LUNI
            IERC20(tokenAddress).approve(address(this), tokenAmount);
            bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
            require(success, "Token transfer failed.");
            _mint(msg.sender, liquidityMinted);

            emit AddLiquidity(msg.sender, msg.value, tokenAmount);
            emit MintLuni(msg.sender, liquidityMinted);

            return liquidityMinted;

        } else {

            // tokenAddress / factoryAddress 0 address checks.
            require(
                tokenAddress != address(0) && factoryAddress != address(0),
                "tokenAddress or factoryAddress failed the Zero Address check."
            );

            // Calculations and state update
            uint256 tokenAmount = _maxTokens;
            uint256 liquidity = address(this).balance;
            balances[msg.sender] += liquidity;

            // Approval, transfer, mint
            IERC20(tokenAddress).approve(address(this), tokenAmount);
            bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
            require(success, "Token transfer failed.");
            _mint(msg.sender, liquidity);

            emit AddLiquidity(msg.sender, msg.value, tokenAmount);
            emit MintLuni(msg.sender, liquidity);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "amount must be greater than 0");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getTokenReserves() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    // -- SWAPS -- //

    // Need to - msg.value from balance as the function has already taken the msg.balance from payable
    // @dev -- Swap ETH for Token functionality.
    function ethToToken(uint256 _minTokens, address recipient) internal {
        uint256 tokenReserve = getTokenReserves();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }

    // @dev -- Swap ETH for Token, called function.
    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    // @dev -- Swap ETH for Token, called function. Send to non msg.sender address.
    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public payable {
        uint256 tokenReserve = getTokenReserves();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    function tokenToTokenSwap(
        uint256 _tokensSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);
        require(exchangeAddress != address(this) && exchangeAddress != address(0), "invalid exchange address");

        uint256 tokenReserve = getTokenReserves();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        IExchange(exchangeAddress).ethToTokenSwap{value: ethBought}(_minTokensBought);
    }

    // -- HELPERS -- //

    // Low level functions -- make it private, why?
    // Would also be pointless to be a public function
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Reserves must be greater than 0");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function getTokenReserves() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputreserve)
    public pure returns (uint256)
    {
        require(inputReserve > 0 && outputreserve > 0, "Reserves must be greater than 0");

        return (inputReserve * 1000) / outputreserve;
    }

    // Will need these to display to FE and calculate outputs
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ETH sold must be over 0");
        uint256 tokenReserve = getTokenReserves();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    // Will need these to display to FE and calculate outputs
    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "Token sold must be over 0");

        uint256 tokenReserve = getTokenReserves();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }
}