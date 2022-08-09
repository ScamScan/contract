// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {ERC165} from "../library/src/ERC165.sol";

import {IERC721Metadata} from "../library/src/interfaces/IERC721Metadata.sol";
import {IERC4973} from "../library/src/interfaces/IERC4973.sol";

bytes32 constant AGREEMENT_HASH =
  keccak256(
    "Agreement(address active,address passive,string tokenURI)"
);

abstract contract ERC4973 is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;

  BitMaps.BitMap internal _usedHashes;  // modified
  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _recipients;  // tokenId to SBT recipients
  mapping(uint256 => address) private _senders;  // tokenId to SBT senders
  mapping(uint256 => int256) private _tokenScores;  // tokenId to SBT repuation score (signed integer)
  mapping(uint256 => string) private _tokenURIs;  // tokenId to tokenURI
  mapping(address => uint256) private _balances;  // address to SBT balance
  mapping(address => int256) private _reputationScores;  // address to total reputation score

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
      interfaceId == type(IERC4973).interfaceId ||  // TODO check
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
    revert("Cannot unequip received Reputation Token.");
    // require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
    // _usedHashes.unset(tokenId);
    // _burn(tokenId);
  }

  function balanceOf(address holder) public view virtual override returns (uint256) {
    require(holder != address(0), "balanceOf: Zero address is not a valid holder");
    return _balances[holder];
  }

  function reputationScoreOf(address holder) public view virtual returns (int256) {  // Check: virtual?
    require(holder != address(0), "reputationScoreOf: Zero address is not a valid holder");
    return _reputationScores[holder];
  }

  function recipientOf(uint256 tokenId) public view virtual returns (address) {
    address recipient = _recipients[tokenId];
    require(recipient != address(0), "recipientOf: Token doesn't exist");
    return recipient;
  }

  function senderOf(uint256 tokenId) public view virtual returns (address) {
    address sender = _senders[tokenId];
    require(sender != address(0), "senderOf: Token doesn't exist");
    return sender;
  }

  function give(
    address to,
    string calldata uri,
    bytes calldata signature,
    int256 tokenScore
  ) external virtual returns (uint256) {
    require(msg.sender != to, "give: cannot give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, uri, signature);
    _mint(msg.sender, to, tokenId, uri, tokenScore);
    _usedHashes.set(tokenId);

    // TODO 1: 대상자 검증
    // TODO 2: MATIC 등 토큰 소각 로직 추가
    return tokenId;
  }

  function take(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
//   ) external virtual {
    revert("Cannot take Reputation Token from others.");
    // require(msg.sender != from, "take: cannot take from self");
    // uint256 tokenId = _safeCheckAgreement(msg.sender, from, uri, signature);
    // _mint(from, msg.sender, tokenId, uri);
    // _usedHashes.set(tokenId);
    // return tokenId;
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    string calldata uri,
    bytes calldata signature
  ) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive, uri);
    uint256 tokenId = uint256(hash);

    require(
      SignatureChecker.isValidSignatureNow(passive, hash, signature),
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
    return _hashTypedDataV4(structHash);
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _recipients[tokenId] != address(0);
  }

  function _mint(
    address from,  // msg.sender
    address to,
    uint256 tokenId,
    string memory uri,
    int256 tokenScore  // TODO check: memory?
  ) internal virtual returns (uint256) {
    require(!_exists(tokenId), "mint: tokenID exists");
    _balances[to] += 1;
    _reputationScores[to] += tokenScore;  // 점수 합산
    _senders[tokenId] = from;
    _recipients[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    _tokenScores[tokenId] = tokenScore;
    emit Transfer(from, to, tokenId);
    return tokenId;
  }

//   function _burn(uint256 tokenId) internal virtual {
//     address owner = ownerOf(tokenId);

//     _balances[owner] -= 1;
//     delete _owners[tokenId];
//     delete _tokenURIs[tokenId];

//     emit Transfer(owner, address(0), tokenId);
//   }
}
