// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TODO:
//  - implement ideas from ClaudesContract.sol:
//    - have a purchase method that is payable so that it accepts ETH to buy an NFT
//       - this implies having a mapping with the price for each NFT and a function to update it
//       - emit an event when the price is updated
//    - have a redeem method that burns the NFT and sends ETH to the owner
//       - this implies having a mapping to mark which tokens are redeemable
//       - emit an event when a token becomes redeemable
//    - make it pausable, and have a modifier to stop minting, purchasing, transfering and redeeming when paused
//       - emit events when pausing and unpausing
//  - apply some best practices from https://github.com/nibbstack/erc721
//    - naming of mappings (for example `tokenToOwner`)
//    - use it to double check implementation of the more complex methods
//  - watch https://www.youtube.com/watch?v=JS_kS-CjFcM
//  - add natspec comments to document all public functions
//  - follow best practices from foundry: https://book.getfoundry.sh/guides/best-practices

import {Errors} from "./Errors.sol";

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event Withdrawal(address indexed to, uint256 balance);
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;
  function getApproved(uint256 tokenId) external view returns (address operator);
  function setApprovalForAll(address operator, bool approved) external;
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers from ERC-721 asset contracts.
 */
interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract CryptoSoldiers is IERC165, IERC721, IERC721Metadata, Errors {
  address private _contractOwner;
  string private _baseURI;
  string private _name;
  string private _symbol;
  uint16 private _totalSupply;

  event TokenPurchased(address buyer, uint256 tokenId);

  mapping(uint256 tokenId => address owner) private _owners;
  mapping(address owner => uint256 balance) private _balances;
  mapping(uint256 tokenId => address approvedAddress) private _tokenApprovals;
  mapping(address owner => mapping(address operator => bool hasPermission))
    private _operatorApprovals;

  constructor(address owner_, string memory name_, string memory symbol_, uint16 totalSupply_) {
    _baseURI = "https://api.cryptosoldiers.com/nft/";
    _name = name_;
    _symbol = symbol_;
    _contractOwner = owner_;
    _totalSupply = totalSupply_;
    _mint(totalSupply_);
  }

  function _requireOwned(uint256 tokenId) internal view returns (address) {
    address owner = _owners[tokenId];
    if (owner == address(0)) {
      revert NonexistentToken(tokenId);
    }
    return owner;
  }

  function _requireForSale(uint256 tokenId) internal view {
    address owner = _owners[tokenId];
    if (owner != _contractOwner) {
      revert TokenNotForSale(tokenId);
    }
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == 0x80ac58cd || // ERC721
      interfaceId == 0x5b5e139f; // ERC721Metadata
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function totalSupply() public view returns (uint16) {
    return _totalSupply;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    _requireOwned(tokenId);
    return string.concat(_baseURI, uint2str(tokenId));
  }

  function changeBaseURI(string memory newBaseURI) public onlyOwner {
    _baseURI = newBaseURI;
  }

  function contractOwner() public view returns (address) {
    return _contractOwner;
  }

  function buyToken(uint256 tokenId) public payable {
    _requireForSale(tokenId);
    // TODO: check if msg.value >= price. I could use Chainlink to get a ETH/USD exchange rate (https://docs.chain.link)

    address to = msg.sender;
    _balances[_contractOwner] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit TokenPurchased(to, tokenId);

    // TODO: return excess payment if any
  }

  function withdraw(address to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, ) = payable(to).call{value: balance}("");
    require(sent, "Failed to withdraw funds");
    emit Withdrawal(to, balance);
  }

  receive() external payable {}

  function balanceOf(address owner) public view returns (uint256) {
    if (owner == address(0)) {
      revert InvalidOwner(address(0));
    }
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    return _requireOwned(tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public {
    if (from == address(0)) {
      revert InvalidSender(from);
    }

    if (to == address(0)) {
      revert InvalidReceiver(to);
    }

    address owner = _requireOwned(tokenId);
    if (owner != from) {
      revert IncorrectOwner(from, tokenId, owner);
    }

    if (
      !_isTokenOwner(tokenId, msg.sender) &&
      !_isApprovedSender(tokenId, msg.sender) &&
      !_isOperator(msg.sender, owner)
    ) {
      revert IncorrectOwner(msg.sender, tokenId, owner);
    }

    _clearApproval(tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
    transferFrom(from, to, tokenId);
    checkOnERC721Received(msg.sender, from, to, tokenId, data);
  }

  function _isTokenOwner(uint256 tokenId, address sender) internal view returns (bool) {
    return _owners[tokenId] == sender;
  }

  function _isApprovedSender(uint256 tokenId, address sender) internal view returns (bool) {
    return _tokenApprovals[tokenId] == sender;
  }

  function _isOperator(address sender, address owner) internal view returns (bool) {
    return _operatorApprovals[owner][sender];
  }

  function _clearApproval(uint256 tokenId) internal {
    _tokenApprovals[tokenId] = address(0);
  }

  function approve(address approvedSender, uint256 tokenId) public {
    if (approvedSender == address(0)) {
      revert InvalidReceiver(approvedSender);
    }

    address owner = _requireOwned(tokenId);
    if (!_isTokenOwner(tokenId, msg.sender) && !_isOperator(msg.sender, owner)) {
      revert IncorrectOwner(msg.sender, tokenId, owner);
    }

    _tokenApprovals[tokenId] = approvedSender;
    emit Approval(owner, approvedSender, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    _requireOwned(tokenId);
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public {
    if (operator == address(0)) {
      revert InvalidOperator(address(0));
    }
    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _isOperator(operator, owner);
  }

  function checkOnERC721Received(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal {
    if (to.code.length > 0) {
      try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (
        bytes4 retval
      ) {
        if (retval != IERC721Receiver.onERC721Received.selector) {
          // Token rejected
          revert InvalidReceiver(to);
        }
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          // non-IERC721Receiver implementer
          revert InvalidReceiver(to);
        } else {
          assembly ("memory-safe") {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  function _mint(uint16 quantity) internal {
    for (uint16 i = 0; i < quantity; i++) {
      _owners[i + 1] = _contractOwner;
      _balances[_contractOwner] += 1;
    }
  }

  function burn(uint256 tokenId) public onlyOwner {
    address owner = _requireOwned(tokenId);
    _balances[owner] -= 1;
    _owners[tokenId] = address(0);
    _tokenApprovals[tokenId] = address(0);
    emit Transfer(owner, address(0), tokenId);
  }

  function uint2str(uint _i) internal pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  modifier onlyOwner() {
    if (msg.sender != _contractOwner) revert NotContractOwner();
    _;
  }
}
