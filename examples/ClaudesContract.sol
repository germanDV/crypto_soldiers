// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  To use this in practice:
    First, batch mint all tokens to yourself (the owner)
    Set the unit price using setUnitPrice
    Enable sales using setSaleState(true)
    Users can then call purchaseUnit with appropriate ETH to buy tokens
    You can withdraw proceeds using withdrawProceeds
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RealEstateNFT is ERC721, ERC721URIStorage, Pausable, Ownable {
  uint256 public constant MAX_UNITS = 200;

  // Rename to totalSupply and make it public?
  // could use "openzeppelin-contracts/utils/Counters.sol"
  uint256 private _tokenIds;

  bool public saleIsActive;
  uint256 public unitPrice; // Make it a mapping because each token can have a different price, but maybe have a default too
  mapping(uint256 => bool) public isRedeemable;
  mapping(uint256 => uint256) public redemptionValues;
  IERC20 public usdcToken;

  event SaleStateChanged(bool isActive);
  event PriceChanged(uint256 newPrice); // Should include the tokenId
  event NFTPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
  event MilestoneReached(uint256 indexed tokenId, string milestone);
  event NFTRedeemed(uint256 indexed tokenId, address indexed owner, uint256 value);

  constructor() ERC721("Real Estate Development", "RED") {
    saleIsActive = false;
    unitPrice = 0;
  }

  function setSaleState(bool _saleIsActive) public onlyOwner {
    saleIsActive = _saleIsActive;
    emit SaleStateChanged(_saleIsActive);
  }

  function setUnitPrice(uint256 _unitPrice) public onlyOwner {
    unitPrice = _unitPrice;
    emit PriceChanged(_unitPrice);
  }

  function setUSDCAddress(address _usdcAddress) public onlyOwner {
    usdcToken = IERC20(_usdcAddress);
  }

  function purchaseUnitUSDC(uint256 tokenId) public {
    require(address(usdcToken) != address(0), "USDC address not set");
    require(saleIsActive, "Sale is not active");
    // TODO: check that tokenId is owned by the contract

    // Transfer USDC from buyer to contract
    require(usdcToken.transferFrom(msg.sender, address(this), unitPrice), "USDC transfer failed");

    // Transfer the NFT to the buyer
    _transfer(owner(), msg.sender, tokenId);

    emit NFTPurchased(tokenId, msg.sender, unitPrice, true);
  }

  function purchaseUnit(uint256 tokenId) public payable {
    // Is it OK to use require here or would it be better to use revert?
    require(saleIsActive, "Sale is not active");
    require(msg.value >= unitPrice, "Insufficient payment");
    // TODO: check that tokenId is owned by the contract

    _transfer(owner(), msg.sender, tokenId);

    // This function already emits a Transfer event, do we want an NFTPurchased as well?
    emit NFTPurchased(tokenId, msg.sender, msg.value);

    // TODO: double-check this logic
    // Return excess payment if any
    if (msg.value > unitPrice) {
      (bool sent, ) = payable(msg.sender).call{value: msg.value - unitPrice}("");
      require(sent, "Failed to return excess payment");
    }
  }

  // Function to withdraw sale proceeds
  function withdrawProceeds() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No proceeds to withdraw");
    (bool sent, ) = payable(owner()).call{value: balance}("");
    require(sent, "Failed to withdraw proceeds");
  }

  function mintUnit(address to, string memory tokenURI) public onlyOwner returns (uint256) {
    require(_tokenIds < MAX_UNITS, "All units have been minted");
    _tokenIds++;
    uint256 newTokenId = _tokenIds;
    _safeMint(to, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    return newTokenId;
  }

  // If we call this one in the constructor, we can make it private and do not require onlyOwner
  function batchMint(
    address to,
    uint256 quantity,
    string[] memory tokenURIs
  ) public onlyOwner returns (uint256[] memory) {
    require(quantity > 0, "Quantity must be greater than 0");
    require(_tokenIds + quantity <= MAX_UNITS, "Would exceed max units");
    require(tokenURIs.length == quantity, "URI array length must match quantity");

    uint256[] memory mintedIds = new uint256[](quantity);

    for (uint256 i = 0; i < quantity; i++) {
      _tokenIds++;
      uint256 newTokenId = _tokenIds;

      _safeMint(to, newTokenId);

      // is this possible to infer the url from _baseURL + tokenId? This whay we save calling this function for each token that is minted
      _setTokenURI(newTokenId, tokenURIs[i]);

      mintedIds[i] = newTokenId;
    }

    return mintedIds;
  }

  // If we keep metadata off-chain this is not necessary, but the event is nice though.
  function updateMilestone(uint256 tokenId, string memory milestone) public onlyOwner {
    // require(super._exists(tokenId), "Token does not exist");
    _requireOwned(tokenId);
    _setTokenURI(tokenId, milestone);
    emit MilestoneReached(tokenId, milestone);
  }

  function batchUpdateMilestones(
    uint256[] memory tokenIds,
    string[] memory milestones
  ) public onlyOwner {
    require(tokenIds.length == milestones.length, "Arrays length mismatch");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(super._exists(tokenIds[i]), "Token does not exist");
      _setTokenURI(tokenIds[i], milestones[i]);
      emit MilestoneReached(tokenIds[i], milestones[i]);
    }
  }

  function makeRedeemable(uint256 tokenId, uint256 value) public onlyOwner {
    require(super._exists(tokenId), "Token does not exist");
    require(!isRedeemable[tokenId], "Token is already redeemable");
    isRedeemable[tokenId] = true;
    redemptionValues[tokenId] = value;
  }

  function redeem(uint256 tokenId) public payable {
    require(super._exists(tokenId), "Token does not exist");
    require(ownerOf(tokenId) == msg.sender, "Not token owner");
    require(isRedeemable[tokenId], "Token is not redeemable");

    uint256 redemptionValue = redemptionValues[tokenId];
    require(address(this).balance >= redemptionValue, "Insufficient contract balance");

    _transfer(msg.sender, address(this), tokenId);

    (bool sent, ) = payable(msg.sender).call{value: redemptionValue}("");
    require(sent, "Failed to send Ether");

    emit NFTRedeemed(tokenId, msg.sender, redemptionValue);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  receive() external payable {}
}
