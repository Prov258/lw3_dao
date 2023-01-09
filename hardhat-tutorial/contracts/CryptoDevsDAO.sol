// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevsNFT.sol";
import "./IFakeNFTMarketplace.sol";

contract CryptoDevsDAO is Ownable {
    ICryptoDevsNFT cryptoDevsNFT;
    IFakeNFTMarketplace nftMarketplace;

    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        YAY,
        NAY
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    modifier inactiveProposalOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            !proposals[_proposalIndex].executed,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    constructor(address _cryptoDevsNFT, address _fakeNFTMarketplace) payable {
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
        nftMarketplace = IFakeNFTMarketplace(_fakeNFTMarketplace);
    }

    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals - 1;
    }

    function voteOnProposal(
        uint256 _proposalIndex,
        Vote _vote
    ) external nftHolderOnly onlyActiveProposal(_proposalIndex) {
        Proposal storage proposal = proposals[_proposalIndex];
        uint256 numVotes = 0;
        uint256 balance = cryptoDevsNFT.balanceOf(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (!proposal.voters[tokenId]) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");
        if (_vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal(
        uint256 _proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(_proposalIndex) {
        Proposal storage proposal = proposals[_proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
