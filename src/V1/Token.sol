// SPDX-License-Identifier: UNLICENSED
pragma solidity  0.8.19;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    constructor (
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) 
    ERC20(name, symbol) 
    {
        _mint(msg.sender, initialSupply);
    }

}

/*
forge create
    --rpc-url https://rpc2.sepolia.org
    --constructor-args "LuniswapV1" "LUNI" 1000000000000000000000
    --private-key <Private-Key>
    .\src\V1\Token.sol:Token

[⠆] Compiling...
No files changed, compilation skipped
Deployer: 0x319d567611c5a1017BA081e2B27B7c7b57e1797d
Deployed to: 0xcD1C927f3DF0206F654E3896a3734bD00E8Bb19B
Transaction hash: 0x4f643674522340195888dbfe6c691d8c584735e5d41ac2cbcf3e970f45caf3c3

"ChainLink" "LINK"
0x73F1e786dFCc837cD3c3C5f3F05Aa98B8D8EfDC0

"Optimism" "OP"
0xFE5974b9e0Cd3fC67689fD980A4A017941f3d1D2

"Polygon" "MATIC"
0xB74B853D30e414e62FDEB1b6d438F048766b7E2f
*/