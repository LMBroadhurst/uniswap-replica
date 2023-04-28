// https://jeiwan.net/

# What is Uniswap?
Uniswap is a decentralized exchange (DEX) that aims to be an alternative to centralized exchanges.

On the lower lever, it’s an algorithm that allows to make pools, or token pairs, and fill them with liquidity to let users exchange tokens using this liquidity. 
The algorithm is called an `automated market maker` or `automated liquidity provider`.

Market makers are entities that provide liquidity (trading assets) to markets. Liquidity is what makes trades possible.

A DEX must have enough (or a lot of) liquidity to function and serve as an alternative to centralized exchanges. The solution is to allow anyone to be a market maker, and this is what makes Uniswap an automated market maker. Any user can deposit their funds into a trading pair (and benefit from that).

## Constant Product Market Maker

Automated market maker is a general term that embraces different decentralized market maker algorithms.

At the core of Uniswap is the constant product function: `x * y = k`

Where x is the tokenA reserve, y is the tokenB reserve, and k is a constant value.
No matter how many tokens are traded for x or y, the constant of k must always remain the same.