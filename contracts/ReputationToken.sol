// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {IERC721Metadata} from "../library/src/interfaces/IERC721Metadata.sol";
import {ERC165} from "../library/src/ERC165.sol";


bytes32 constant AGREEMENT_HASH = keccak256(
<<<<<<< HEAD
   "Agreement(address active,address passive,string uri)"
);

=======
  "Agreement(address active,address passive,string uri)"
);
>>>>>>> 4329682b

struct RepToken {
    address from;
    address to;
    int256 score;  // signed integer
    uint256 tokenId;
    uint256 relatedTransactionHash;  // report 하는 대상 트랜잭션 해시값 (in uint256 type)
    uint256 amountOfBurntAsset;
    uint256 blockTimestamp;
    string reportTypeCode;  // report 하는 이유 유형
}

<<<<<<< HEAD

contract ReputationToken is EIP712, IERC721Metadata, ERC165 {
=======
contract ReputationToken is EIP712, ERC165, IERC721Metadata {
>>>>>>> 4329682b

  using BitMaps for BitMaps.BitMap;
  
  // BitMap: mapping (uint256 => bool)
  BitMaps.BitMap private _usedTokenIdHashes;  // BitMap to store used Token Id
  BitMaps.BitMap private _usedTransactionHashes;  // BitMap to store used Transaction hash

  string private _name;
  string private _symbol;
  uint256 private _totalSupply;

  string private _burntAssetSymbol;  // Asset symbol to burn for the minting
  address private _maticBurnContract = 0x70bcA57F4579f58670aB2d18Ef16e02C17553C38;
  address payable private _payableMaticBurnContract = payable(_maticBurnContract);

  mapping(address => RepToken[]) private sentReputationTokens;
  mapping(address => RepToken[]) private receivedReputationTokens;

  mapping(uint256 => address) private _owners;  // tokenID to owner address

  mapping(address => uint256) private _balances;  // address to SBT balance
  mapping(address => int256) private _reputationScores;  // address to total reputation score

  // uint256 tempTokenId = 0;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory version_
  ) EIP712(name_, version_) {
    _name = name_;
    _symbol = symbol_;
  }

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  function _safeCheckAgreement(
<<<<<<< HEAD
    address active,  // msg.sender
    address passive,  // to
=======
    address active,
    address passive,
>>>>>>> 4329682b
    string calldata uri,
    bytes calldata signature
  ) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive, uri);
    uint256 tokenId = uint256(hash);

<<<<<<< HEAD
   require(
     SignatureChecker.isValidSignatureNow(passive, hash, signature),
     "_safeCheckAgreement: invalid signature"
   );
=======
    require(
      SignatureChecker.isValidSignatureNow(active, hash, signature),
      "_safeCheckAgreement: invalid signature"
    );
>>>>>>> 4329682b
    require(!_usedTokenIdHashes.get(tokenId), "_safeCheckAgreement: already used");
    return tokenId;
  }

  function _getHash(
    address active,
    address passive,
    string calldata uri
  ) internal view returns (bytes32) {
    bytes32 structHash = keccak256(
<<<<<<< HEAD
      abi.encode(
        AGREEMENT_HASH,
        active,
        passive,
        keccak256(bytes(uri))
      )
=======
      abi.encode(AGREEMENT_HASH, active, passive, keccak256(bytes(uri)))
>>>>>>> 4329682b
    );
    return _hashTypedDataV4(structHash);  // bytes32
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external pure returns (string memory) {
	    revert("no tokenURI used.");
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function unequip(uint256 tokenId) public virtual {
    revert("Cannot unequip received Reputation Token.");
  }

  function balanceOf(address holder) public view virtual returns (uint256) {
    require(holder != address(0), "balanceOf: Zero address is not a valid holder");
    return _balances[holder];
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    return _owners[tokenId];
  }

  function reputationScoreOf(address holder) public view virtual returns (int256) {  // Check: virtual?
    require(holder != address(0), "reputationScoreOf: Zero address is not a valid holder");
    return _reputationScores[holder];
  }

  function sentTokensOf(address sender) public view returns (RepToken[] memory) {
    require(sender != address(0), "sentTokensOf: Zero address is not a valid sender");
    return sentReputationTokens[sender];
  }

  function receivedTokensOf(address recipient) public view returns (RepToken[] memory) {
    require(recipient != address(0), "receivedTokensOf: Zero address is not a valid recipient");
    return receivedReputationTokens[recipient];
  }

  function getBurningAmount(int256 score) public pure returns (uint256) {
    uint256 baseBurningFee = 10;
    return uint256(score ** 2) + baseBurningFee;  // score^2 + baseBurningFee
  }

  function _burnFee(uint _amount) public payable {
    _payableMaticBurnContract.transfer(_amount);
  }

  function _validateScoreMinMax(int256 score) private pure returns (bool) {
    int256 min = -100;
    int256 max = 100;
    return score >= min && score <= max;
  }

  function give(
    address from,
    address to,
    string calldata uri,
    bytes calldata signature,
    int256 score,
    uint256 relatedTransactionHash,
    string calldata reportTypeCode
  ) external virtual payable returns (uint256) {
    require(msg.sender != to, "give: cannot give from self.");
    require(_validateScoreMinMax(score), "give: invalid score value.");
<<<<<<< HEAD
    
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, uri, signature);
    // uint256 tokenId = tempTokenId;
    // tempTokenId += 1;  // temp: for deployment test
=======

     uint256 tokenId = _safeCheckAgreement(from, to, uri, signature);
>>>>>>> 4329682b

    uint256 burningAmount = getBurningAmount(score);
    _burnFee(msg.value);
    _setUsedTransactionHash(relatedTransactionHash);

    bool succeed = _mint(from, to, score, tokenId, burningAmount, relatedTransactionHash, reportTypeCode);
    require(succeed, "minting failed.");
    _usedTokenIdHashes.set(tokenId);
    return tokenId;
  }

  function isUsedTransactionHash(uint256 _transactionHash) public view returns (bool) {
    return _usedTransactionHashes.get(_transactionHash);
  }

  function _setUsedTransactionHash(uint256 _transactionHash) private {
    require(!isUsedTransactionHash(_transactionHash), "_setUsedTransactionHash: already used transaction hash.");  // 이미 사용된 적 있는 transaction hash인지 검증
    _usedTransactionHashes.set(_transactionHash);
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }
  
  function _mint(
    address _from,
    address _to,
    int256 _score,
    uint256 _tokenId,
    uint256 _burningAmount,
    uint256 _relatedTransactionHash,
    string memory _reportTypeCode
  ) internal virtual returns (bool) {
    
    require(!_exists(_tokenId), "mint: tokenID exists");

    _balances[_to] += 1;
    _totalSupply += 1;
    _reputationScores[_to] += _score;
    _owners[_tokenId] = _to;

    RepToken memory repToken = RepToken({  // Token instance
      from: _from,
      to: _to,
      score: _score,
      tokenId: _tokenId,
      amountOfBurntAsset: _burningAmount,
      reportTypeCode: _reportTypeCode,
      blockTimestamp: block.timestamp,
      relatedTransactionHash: _relatedTransactionHash
    });
    
    // Push token instance to token struct arrays.
    sentReputationTokens[_from].push(repToken);
    receivedReputationTokens[_to].push(repToken);
    emit Transfer(_from, _to, _tokenId);
    return true;
  }
}