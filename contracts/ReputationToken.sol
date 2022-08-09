// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {ERC165} from "../library/src/ERC165.sol";

import {IERC721Metadata} from "../library/src/interfaces/IERC721Metadata.sol";
import {IERC4973} from "../library/src/interfaces/IERC4973.sol";


// TODO 1: MATIC 등 토큰 소각 로직 개선 (transfer to the Zero Address?)
// TODO 2: 이 tx hash가 이미 sbt 발급된 적 있는지 검증
// 컨트랙트에서 merkle tree 등으로 관리하기? => is IN 조회
// TODO 3: minMaxValidator to score: DONE

bytes32 constant AGREEMENT_HASH =
  keccak256(
    "Agreement(address active,address passive,string tokenURI)"
);

struct ReputationToken {
    int256 score;
    uint256 tokenId;
    uint256 amountOfBurntAsset;
    string reportTypeCode;  // report 하는 이유 유형
    string relatedTransactionHash;  // report 하는 대상 트랜잭션 해시값
}

abstract contract ERC4973 is EIP712, ERC165, IERC721Metadata, IERC4973 {
  using BitMaps for BitMaps.BitMap;

  BitMaps.BitMap internal _usedHashes;  // modified
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

  // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
  //   require(_exists(tokenId), "tokenURI: token doesn't exist");
  //   return _tokenURIs[tokenId];
  // }

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

  // function recipientOf(uint256 tokenId) public view virtual returns (address) {
  //   address recipient = _recipients[tokenId];
  //   require(recipient != address(0), "recipientOf: Token doesn't exist");
  //   return recipient;
  // }

  // function senderOf(uint256 tokenId) public view virtual returns (address) {
  //   address sender = _senders[tokenId];
  //   require(sender != address(0), "senderOf: Token doesn't exist");
  //   return sender;
  // }

  function _getBurningAmount(int256 score) private pure returns (uint256) {
    uint256 baseBurningFee = 10;
    return uint256(score ** 2) + baseBurningFee;  // score^2 + baseBurningFee
  }

  function _burnFee(uint256 _amount) public payable {  // TODO: public?
    // TODO: 소각 매커니즘 개선 (caller가 소각분을 지불해야 함)
    bool succeed = _payableMaticBurnContract.send(_amount);
    require(succeed, "Burn Failure. ");
  }

  function _validateScoreMinMax(int256 score) private pure returns (bool) {
    int256 min = -100;  // TODO: constructor로 빼기
    int256 max = 100;
    return score >= min && score <= max;
  }

  function give (
    address _to,
    string calldata _uri,
    bytes calldata _signature,
    int256 _score,
    string calldata _reportTypeCode,
    string calldata _relatedTransactionHash
  ) external virtual payable returns (uint256) {
    require(msg.sender != _to, "give: cannot give from self.");
    require(_validateScoreMinMax(_score), "give: invalid score value.");

    uint256 tokenId = _safeCheckAgreement(msg.sender, _to, _uri, _signature);

    uint256 burningAmount = _getBurningAmount(_score);
    _burnFee(burningAmount);

    _mint(msg.sender, _to, _score, tokenId, burningAmount, _reportTypeCode, _relatedTransactionHash);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  // function take(
  //   address from,
  //   string calldata uri,
  //   bytes calldata signature
  // ) external virtual returns (uint256) {
  //   revert("Cannot take Reputation Token from others.");
  // }

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
    return _owners[tokenId] != address(0);
  }
  
  function _mint(
    address _from,
    address _to,
    int256 _score,
    uint256 tokenId,
    uint256 burningAmount,
    string memory _reportTypeCode,
    string memory _relatedTransactionHash
  ) internal virtual returns (uint256) {
    
    require(!_exists(tokenId), "mint: tokenID exists");

    _balances[_to] += 1;
    _reputationScores[_to] += _score;
    _owners[tokenId] = _to;

    ReputationToken memory repToken = ReputationToken({  // Token instance
      score: _score,
      tokenId: tokenId,
      amountOfBurntAsset: burningAmount,
      reportTypeCode: _reportTypeCode,
      relatedTransactionHash: _relatedTransactionHash
    });
    
    // Push token instance to token struct arrays.
    sentReputationTokens[msg.sender].push(repToken);
    receivedReputationTokens[_to].push(repToken);
  }
}