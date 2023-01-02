//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_token_counter;

    event DogMinted(uint256 indexed tokenId);

    constructor() ERC721("Doggie", "Dog") {
        s_token_counter = 0;
    }

    function mintNft() public returns (uint256) {
        _safeMint(msg.sender, s_token_counter);
        emit DogMinted(s_token_counter);
        s_token_counter = s_token_counter + 1;
    }

    function tokenURI(uint256 /*token_Id*/) public view override returns (string memory) {
        return TOKEN_URI;
    }

    function token_Counter() public view returns (uint256) {
        return s_token_counter;
    }
}
