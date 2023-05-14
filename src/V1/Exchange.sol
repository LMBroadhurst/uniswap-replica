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
    uint256 public totalSupply;
    mapping(address userLuniAddress => uint256 userLuniBalance) balances;
    mapping(address userAddress => mapping(address approvedAddress => uint256 amount)) allowances;

    // Events
    event TokenPurchase(address indexed buyer, uint256 indexed ethSold, uint256 indexed tokensBought);
    event EthPurchase(address indexed buyer, uint256 indexed tokensSold, uint256 indexed ethBought);
    event AddLiquidity(address indexed provider, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event RemoveLiquidity(address indexed buyer, uint256 indexed ethAmount, uint256 indexed tokenAmount);
    event Transfer(address indexed buyer, uint256 indexed _to, uint256 indexed _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _value);

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
    public payable returns (uint256 liquidity_) {

        // input validation checks.
        require(_deadline > block.timestamp &&
                _maxTokens > 0 &&
                msg.value > 0, "Error with inputs"
        );

        if (totalSupply > 0) {

            require(_minLiquidity > 0, "_minLiquidity must be greater than 0.");

            // Need to - msg.value from balance as the function has already taken the msg.balance from payable
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getTokenReserves();

            uint256 tokenAmount = (msg.value * tokenReserve) / (ethReserve + 1);
            uint256 liquidityMinted = (msg.value * totalSupply) / ethReserve;

            //
            require(_maxTokens >= tokenAmount, "x"); // line 57

            require(_tokenAmount >= tokenAmount, "insufficient token amount");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);

            _mint(msg.sender, liquidity);

            return liquidity;

        } else {

            // tokenAddress / factoryAddress 0 address checks.
            require(
                tokenAddress != 0 && factoryAddress != 0,
                "tokenAddress or factoryAddress failed the Zero Address check."
            );

            uint256 tokenAmount = _maxTokens;
            uint256 initialLiquidity = address(this).balance;
            balances[msg.sender] += initialLiquidity;


            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            _mint(msg.sender, liquidity);

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