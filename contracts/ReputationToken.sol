// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {ERC4973} from "../library/src/ERC4973.sol";

contract ReputationToken is ERC4973 {
    constructor() public ERC4973("REPUTATION", "REP", "1") {}
}