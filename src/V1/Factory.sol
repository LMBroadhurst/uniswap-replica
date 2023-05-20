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

/*
forge create
    --rpc-url https://rpc2.sepolia.org
    --private-key
    .\src\V1\Factory.sol:Factory

Deployer: 0x319d567611c5a1017BA081e2B27B7c7b57e1797d
Deployed to: 0x227DF48dc788Eb7f8907388E7A11873c84fc609b
Transaction hash: 0xacdb09109a3aee14ff934bede3f8c391a147ab6700db0221f4d29c8f20904928
*/