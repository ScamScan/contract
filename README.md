# ETHSeoul 2022 Submission: ScamScan
## Introduction
* Track someone's reputation on the Ethereum blockchain
### Give: SBT minting + signing (amount, comment) + sending
1. Verify whether the opponent is give-able (SBT minting + signing)
2. If eligible => send SBT + MATIC (or other tokens) to be burnt (by signing Metamask wallet)
3. Check: Search by specific addresses then check SBT list and score sum
4. MyPage: Check the list of received & sent SBT tokens (which requires additional signature)
### Contract Address on Polygon Mumbai Testnet
* [0x393746Ed031641F66F77ea05C85F745E16b3eBcD](https://polygonscan.com/address/0x393746Ed031641F66F77ea05C85F745E16b3eBcD)
### General
* To reference from the implementation of [ERC4973](https://eips.ethereum.org/EIPS/eip-4973), create new SBT tokens implementations
* FYI: From the specification of EIP4973, the methods of `unequip()` and `take()` are not implemented since it has no features, so that to be reverted if it is called.
