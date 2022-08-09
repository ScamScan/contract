// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {ERC165} from "./ERC165.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";

bytes32 constant AGREEMENT_HASH =
  keccak256(
    "Agreement(address active,address passive,string tokenURI)"
);

/// @notice Reference implementation of EIP-4973 tokens.
/// @author Tim Daubenschütz, Rahul Rumalla (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973.sol)
abstract contract ERC4973 is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap internal _usedHashes;  // modified

  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _owners;  // tokenID to owner address
  mapping(uint256 => string) private _tokenURIs;  // tokenID to token URI
  mapping(address => uint256) private _balances;  // address to token balance

  constructor(
    string memory name_,
    string memory symbol_,
    string memory version
  ) EIP712(name_, version) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function unequip(uint256 tokenId) public virtual override {
    require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
    _usedHashes.unset(tokenId);
    _burn(tokenId);
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "balanceOf: address zero is not a valid owner");
    return _balances[owner];
  }


  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function give(
    address to,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    require(msg.sender != to, "give: cannot give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, uri, signature);  // get tokenId (uint256)
    _mint(msg.sender, to, tokenId, uri);
    _usedHashes.set(tokenId);  // tokenId 기록
    return tokenId;
  }

  function take(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    require(msg.sender != from, "take: cannot take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, uri, signature);
    _mint(from, msg.sender, tokenId, uri);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  // sender, recipient의 주소와 토큰 uri의 keccak 해싱 결과를 uint256으로 형 변환한 것이 tokenId
  function _safeCheckAgreement(
    address active,  // msg.sender
    address passive,  // to(give일 경우)
    string calldata uri,
    bytes calldata signature
  ) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive, uri);
    uint256 tokenId = uint256(hash);

    require(
      SignatureChecker.isValidSignatureNow(passive, hash, signature),  // how the signature is generated?
      "_safeCheckAgreement: invalid signature"
    );
    require(!_usedHashes.get(tokenId), "_safeCheckAgreement: already used");
    return tokenId;
  }

  function _getHash(
    address active,
    address passive,
    string calldata uri
  ) internal view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(
        AGREEMENT_HASH,
        active,
        passive,
        keccak256(bytes(uri))
      )
    );
    return _hashTypedDataV4(structHash);  // bytes32
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _mint(
    address from,
    address to,
    uint256 tokenId,
    string memory uri
  ) internal virtual returns (uint256) {
    require(!_exists(tokenId), "mint: tokenID exists");
    _balances[to] += 1;
    _owners[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    emit Transfer(from, to, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];
    delete _tokenURIs[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }
}
