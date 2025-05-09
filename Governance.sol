// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Governance {
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool approved;
    }

    IERC20 public daoToken;
    address public founder;
    uint256 public proposalDuration = 3 days;
    uint256 public proposalCount;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    constructor(address _token) {
        daoToken = IERC20(_token);
        founder = msg.sender;
    }

    function createProposal(string calldata title, string calldata description) external returns (uint256) {
        uint256 id = ++proposalCount;
        proposals[id] = Proposal({
            id: id,
            proposer: msg.sender,
            title: title,
            description: description,
            voteStart: block.timestamp,
            voteEnd: block.timestamp + proposalDuration,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            approved: false
        });
        return id;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteStart, "Voting not started");
        require(block.timestamp <= p.voteEnd, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = daoToken.balanceOf(msg.sender);
        require(weight > 0, "No tokens");

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        hasVoted[proposalId][msg.sender] = true;
    }

    function finalize(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.voteEnd, "Voting not ended");
        require(!p.executed, "Already finalized");

        p.executed = true;

        if (p.forVotes > p.againstVotes) {
            p.approved = true;
        }
    }

    function isProposalApproved(uint256 proposalId) external view returns (bool) {
        return proposals[proposalId].approved;
    }
}
