// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Exchange.sol";

contract Factory {
    mapping(address token => address exchange) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns (address) {
        require(_tokenAddress != address(0), "Token address cannot be 0");
        require(tokenToExchange[_tokenAddress] == address(0), "exchange already exists");

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    // -- HELPERS -- //

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}