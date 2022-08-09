// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {ERC4973} from "../library/src/ERC4973.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";


contract ReputationToken is ERC4973 {
  
  // call constructor of ERC4973
  constructor(
    string memory name_,
    string memory symbol_,
    string memory version
  ) ERC4973(name_, symbol_, version) {}


  function unequip(uint256 tokenId) public virtual override {
  revert("cannot unequip the Reputation Token.");
  // require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
  // _usedHashes.unset(tokenId);
  // _burn(tokenId);
  }

//     function take (
//     address from,
//     string calldata uri,
//     bytes calldata signature
//   ) external virtual override returns (uint256) {
//     revert("cannot take the Reputation Token from others.");
//     // require(msg.sender != from, "take: cannot take from self");
//     // uint256 tokenId = _safeCheckAgreement(msg.sender, from, uri, signature);
//     // _mint(from, msg.sender, tokenId, uri);
//     // _usedHashes.set(tokenId);
//     // return tokenId;
//     return 0;
// }

  function take(address from, string calldata uri, bytes calldata signature) external virtual override returns (uint256) {
    revert("cannot take the Reputation Token from others.");
  }

}
