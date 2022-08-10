// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import {IERC721Metadata} from "../library/src/interfaces/IERC721Metadata.sol";
import {IERC4973} from "../library/src/interfaces/IERC4973.sol";

import {ERC165} from "../library/src/ERC165.sol";


bytes32 constant AGREEMENT_HASH =
  keccak256(
    "Agreement(address active,address passive)"
);

struct ReputationToken {
    int256 score;  // signed integer
    uint256 tokenId;
    uint256 relatedTransactionHash;  // report 하는 대상 트랜잭션 해시값 (in uint256 type)
    uint256 amountOfBurntAsset;
    string reportTypeCode;  // report 하는 이유 유형
}

abstract contract ERC4973 is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;
  
  // BitMap: mapping (uint256 => bool)
  BitMaps.BitMap private _usedTokenIdHashes;
  BitMaps.BitMap private _usedTransactionHashes;

  string private _name;
  string private _symbol;
  string private _burntAssetSymbol;  // 어떤 자산을 소각하여 점수를 매길 것인지 symbol 표시
  address private _maticBurnContract = 0x70bcA57F4579f58670aB2d18Ef16e02C17553C38;
  address payable private _payableMaticBurnContract = payable(_maticBurnContract);  // TODO refactor (from contract object?)

  mapping(address => ReputationToken[]) private sentReputationTokens;
  mapping(address => ReputationToken[]) private receivedReputationTokens;

  mapping(uint256 => address) private _owners;  // tokenID to owner address

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

  // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
  //   return
  //     interfaceId == type(IERC721Metadata).interfaceId ||
  //     interfaceId == type(IERC4973).interfaceId ||  // TODO check
  //     super.supportsInterface(interfaceId);
  // }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function unequip(uint256 tokenId) public virtual override {
    revert("Cannot unequip received Reputation Token.");
  }

  function balanceOf(address holder) public view virtual override returns (uint256) {
    require(holder != address(0), "balanceOf: Zero address is not a valid holder");
    return _balances[holder];
  }

  function reputationScoreOf(address holder) public view virtual returns (int256) {  // Check: virtual?
    require(holder != address(0), "reputationScoreOf: Zero address is not a valid holder");
    return _reputationScores[holder];
  }

  function sentTokensOf(address sender) public view returns (ReputationToken[] memory) {
    require(sender != address(0), "sentTokensOf: Zero address is not a valid sender");
    return sentReputationTokens[sender];
  }

  function receivedTokensOf(address recipient) public view returns (ReputationToken[] memory) {
    require(recipient != address(0), "receivedTokensOf: Zero address is not a valid recipient");
    return sentReputationTokens[recipient];
  }

  // TODO check: 단위 맞는지 check
  function _getBurningAmount(int256 score) private pure returns (uint256) {
    uint256 baseBurningFee = 10;
    return uint256(score ** 2) + baseBurningFee;  // score^2 + baseBurningFee
    // return 1;  // temporary
  }

  function _burnFee(uint256 _amount) public payable {
    bool succeed = _payableMaticBurnContract.send(_amount);  // TODO check: msg.sender의 자산을 소각하는지 확인
    require(succeed, "Burn Failure. ");
  }

  function _validateScoreMinMax(int256 score) private pure returns (bool) {
    int256 min = -100;  // TODO: constructor로 빼기
    int256 max = 100;
    return score >= min && score <= max;
  }

  function give (
    address to,
    bytes calldata signature,
    int256 score,
    uint256 relatedTransactionHash,
    uint256 transactionHash,
    string calldata reportTypeCode
  ) external virtual payable returns (uint256) {
    require(msg.sender != to, "give: cannot give from self.");
    require(_validateScoreMinMax(score), "give: invalid score value.");

    uint256 tokenId = _safeCheckAgreement(msg.sender, to, signature);

    uint256 burningAmount = _getBurningAmount(score);
    _burnFee(burningAmount);
    _setUsedTransactionHash(transactionHash);

    _mint(msg.sender, to, score, tokenId, burningAmount, relatedTransactionHash, reportTypeCode);
    _usedTokenIdHashes.set(tokenId);
    return tokenId;
  }

  function _setUsedTransactionHash(uint256 _transactionHash) private {
    require(!_usedTransactionHashes.get(_transactionHash), "_setUsedTransactionHash: already used transaction hash.");  // 이미 사용된 적 있는 transaction hash인지 검증
    _usedTransactionHashes.set(_transactionHash);
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    bytes calldata signature
  ) internal virtual returns (uint256) {
    bytes32 hash = _getHash(active, passive);
    uint256 tokenId = uint256(hash);

    require(
      SignatureChecker.isValidSignatureNow(passive, hash, signature),
      "_safeCheckAgreement: invalid signature"
    );
    require(!_usedTokenIdHashes.get(tokenId), "_safeCheckAgreement: already used tokenId hash.");
    return tokenId;
  }

  function _getHash(
    address active,
    address passive
  ) internal view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(
        AGREEMENT_HASH,
        active,
        passive
      ));
    return _hashTypedDataV4(structHash);
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
    _reputationScores[_to] += _score;
    _owners[_tokenId] = _to;

    ReputationToken memory repToken = ReputationToken({  // Token instance
      score: _score,
      tokenId: _tokenId,
      amountOfBurntAsset: _burningAmount,
      reportTypeCode: _reportTypeCode,
      relatedTransactionHash: _relatedTransactionHash
    });
    
    // Push token instance to token struct arrays.
    sentReputationTokens[_from].push(repToken);
    receivedReputationTokens[_to].push(repToken);
    
    return true;
  }
}