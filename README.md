# ETHSeoul 2022 Submission: ScamScan
## Introduction
* Scamscan is a reputation platform using SBT with the quadratic burning mechanism. With Scamscan, you could track someone's reputation for interaction, which could prevent user's malicious actions.
### Features
* Positive / Negative Reputation Points
* Verifying tx log
* Quadratic Burning
### Fee Mechanism
* We would charge 10 MATIC as a constant fee to prevent malicious distortion of reputation with a low fee. We could express the total fee as below.
* p = reputation quadratic burning
* c = constant fee = 10 MATIC 
* r = gas fee
* R = total fee = p^2 + c + r
### Give: SBT minting + signing (amount, comment) + sending
1. Verify whether the opponent is give-able (SBT minting + signing)
2. If eligible => send SBT + MATIC (or other tokens) to be burnt (by signing Metamask wallet)
3. Check: Search by specific addresses then check SBT list and score sum
4. MyPage: Check the list of received & sent SBT tokens (which requires additional signature)
### Contract Address on Polygon Mumbai Testnet
* [0x393746Ed031641F66F77ea05C85F745E16b3eBcD](https://polygonscan.com/address/0x393746Ed031641F66F77ea05C85F745E16b3eBcD)
### General
* When implementing the proposed standard of [ERC4973](https://eips.ethereum.org/EIPS/eip-4973), we referenced the sample implementations of the interface on the link.
* FYI: From the specification of EIP4973, the methods of `unequip()` and `take()` are not implemented since it has no features, so that to be reverted if it is called by users.
