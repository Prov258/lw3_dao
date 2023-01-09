// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
    uint256 constant priceNFT = 0.01 ether;

    mapping(uint256 => address) public tokens;

    function purchase(uint256 _tokenId) public payable {
        require(msg.value >= priceNFT, "Not enough ETH sent");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external pure returns (uint256) {
        return priceNFT;
    }

    function available(uint256 _tokenId) external view returns (bool) {
        return tokens[_tokenId] == address(0);
    }
}
