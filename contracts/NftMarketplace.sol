//SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

//imports

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//errors

error NftMarketplace_ProductListingMustBeAboveZero();
error NftMarketplace_NotApprovedForMarketPlace();
error NftMarketplace_ItemAlreadylisted(address nftaddress, uint256 tokenID);
error NftMarketplace_NotOwner();
error NftMarketplace_ItemNotListed(address nftaddress, uint256 tokenId);
error NftMarketplace_PriceDoesnotMatch(address nftaddress, uint256 tokenId, uint256 price);
error NftMarketplace_NoFundsToProceed();
error NftMarketplace_TransferFailed();

contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }
    event Itemlisted(
        address indexed seller,
        address indexed nftaddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftaddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemCancelled(
        address indexed seller,
        address indexed Nftaddress,
        uint256 indexed tokenId
    );
    // NFT contract address-> NFT token id-> listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    //Seller address to amount earned
    mapping(address => uint256) private s_proceeds;

    modifier notListed(
        address nftaddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftaddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace_ItemAlreadylisted(nftaddress, tokenId);
        }
        _;
    }
    modifier isOwner(
        address nftaddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftaddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace_NotOwner();
        }
        _;
    }
    modifier isListed(address nftaddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftaddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace_ItemNotListed(nftaddress, tokenId);
        }
        _;
    }

    function listItems(
        address nftaddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftaddress, tokenId, msg.sender) isOwner(nftaddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace_ProductListingMustBeAboveZero();
        }
        //owner can still hold the nft and provide approval to sell the NFT for them.
        IERC721 nft = IERC721(nftaddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace_NotApprovedForMarketPlace();
        }
        s_listings[nftaddress][tokenId] = Listing(price, msg.sender);
        emit Itemlisted(msg.sender, nftaddress, tokenId, price);
    }

    function buyItem(
        address nftaddress,
        uint256 tokenId
    ) external payable nonReentrant isListed(nftaddress, tokenId) {
        Listing memory listedItem = s_listings[nftaddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NftMarketplace_PriceDoesnotMatch(nftaddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        delete (s_listings[nftaddress][tokenId]);
        IERC721(nftaddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftaddress, tokenId, listedItem.price);
    }

    function cancelItem(
        address nftaddress,
        uint256 tokenId
    ) external isOwner(nftaddress, tokenId, msg.sender) isListed(nftaddress, tokenId) {
        delete (s_listings[nftaddress][tokenId]);
        emit ItemCancelled(msg.sender, nftaddress, tokenId);
    }

    function updateListing(
        address nftaddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(nftaddress, tokenId) isOwner(nftaddress, tokenId, msg.sender) {
        s_listings[nftaddress][tokenId].price = newPrice;
        emit Itemlisted(msg.sender, nftaddress, tokenId, newPrice);
    }

    function withdrawfunds() external {
        uint256 funds = s_proceeds[msg.sender];
        if (funds >= 0) {
            revert NftMarketplace_NoFundsToProceed();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: funds}("");
        if (!success) {
            revert NftMarketplace_TransferFailed();
        }
    }

    //Getter Functions
    function getListing(
        address nftaddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftaddress][tokenId];
    }

    function getfundsEarned(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}

//   1. `listItems` : item to list
//   2. `Buyitem` : buy item already listed.
//   3. `cancelItem`: cancel a listing.
//   4. `updateListing`:update the price of the existing listed items.
//   5. `withdrawProcess`:Withdraw payment for already bought items.
