pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/ERC4973.sol";
import {console} from "forge-std/console.sol";

contract ERC4973Test is Test {
    ERC4973 SBTToken;
    using ECDSA for bytes32;
    bytes32 constant SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    bytes32 constant AGREEMENT_HASH = keccak256(
        "Agreement(address active,address passive,string tokenURI)"
    );
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 private DOMAIN_SEPARATOR;

    function setUp() external {
        SBTToken = new ERC4973("SBT", "SBT", "0.1");
        DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes("SBT")), keccak256(bytes("0.1")), 31337, address(SBTToken), SALT));
        console.logBytes32(DOMAIN_SEPARATOR);
    }

    function test_SHOULD_GIVE_NEW_SBT() external {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address to = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        bytes32 structHash = keccak256(abi.encode(AGREEMENT_HASH, msg.sender, to, keccak256(bytes("KyochonToken"))));
        console.log("structHash Test");
        console.logBytes32(structHash);
        console.log("msg.sender TEST", msg.sender);
        console.log("to TEST", to);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey, keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash))
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        console.log("Signature");
        console.logBytes(signature);
        uint256 tokenId = SBTToken.give(
            msg.sender,
            to,
            "KyochonToken",
            signature
        );
        console.log(tokenId);
        assertEq(tokenId, 1);
    }
}