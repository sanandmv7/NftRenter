// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTRent {
    struct Rental {
        address renter;
        uint256 price;
        uint256 expiry;
        uint256 tokenId;
    }

    address nftContractAddress;

    mapping (uint256=>Rental) tokenIdToRental;
    mapping (uint256=>uint256) tokenIdToPrice;
    mapping (uint256=>uint256) tokenIdToExpiry;
    mapping (uint256=>address) tokenIdToRentee;
    uint256[] availableForRent;

    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
    }

    function listNft(uint256 _price, uint256 _time, uint256 _tokenId) public {
        require(IERC721(nftContractAddress).ownerOf(_tokenId) == msg.sender, "caller is not the owner of the token");
        tokenIdToPrice[_tokenId] = _price;
        tokenIdToExpiry[_tokenId] = _time;
        tokenIdToRentee[_tokenId] = msg.sender;
        availableForRent.push(_tokenId);
    }

    function rentNft(uint256 _tokenId) public payable {
        require(tokenIdToPrice[_tokenId] > 0, "Token not available for rent");
        require(msg.value == tokenIdToPrice[_tokenId], "Payment doesn't match the price");
        tokenIdToRental[_tokenId] = Rental(msg.sender, tokenIdToPrice[_tokenId], block.timestamp+tokenIdToExpiry[_tokenId], _tokenId);
        tokenIdToPrice[_tokenId] = 0;
        _removeAvailable(_tokenId);
        IERC721(nftContractAddress).transferFrom(tokenIdToRentee[_tokenId], msg.sender, _tokenId);
    }

    function returnNft(uint256 _tokenId) public {
        require(tokenIdToRental[_tokenId].renter == msg.sender, "caller didn't rent any nft");
        IERC721(nftContractAddress).transferFrom(msg.sender, tokenIdToRentee[_tokenId], _tokenId);
        uint256 renteeAmount = tokenIdToRental[_tokenId].price/10;
        uint256 renterAmount = tokenIdToRental[_tokenId].price-renteeAmount;
        delete tokenIdToRental[_tokenId];
        payable(tokenIdToRentee[_tokenId]).transfer(renteeAmount);
        payable(tokenIdToRentee[_tokenId]).transfer(renterAmount);
    }

    function withdrawPrice(uint256 _tokenId) public {
        require(tokenIdToRentee[_tokenId] == msg.sender, "caller is not the rentee");
        require(block.timestamp > tokenIdToRental[_tokenId].expiry, "not expired yet");
        uint256 amount = tokenIdToRental[_tokenId].price;
        payable(msg.sender).transfer(amount);
    }

    function _removeAvailable(uint256 _tokenId) internal {
        for(uint i=0; i<availableForRent.length; i++) {
            if(availableForRent[i] == _tokenId) {
                availableForRent[i] = availableForRent[availableForRent.length-1];
                delete availableForRent[availableForRent.length-1];
                break;
            }
        }
    }
}