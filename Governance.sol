// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IDAOConfig {
    function voteFrequencyDays() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function quorumPercent() external view returns (uint256);
    function votingEnabled() external view returns (bool);
}

contract Governance {
    address public daoConfig;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public lastProposalTimestamp;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed id, address proposer, string description);
    event Voted(uint256 indexed id, address voter, bool support);
    event ProposalExecuted(uint256 indexed id);

    constructor(address _daoConfig) {
        daoConfig = _daoConfig;
    }

    function createProposal(string calldata _description) external {
        require(IDAOConfig(daoConfig).votingEnabled(), "Voting not active");
        uint256 throttle = IDAOConfig(daoConfig).voteFrequencyDays() * 1 days;
        require(
            block.timestamp >= lastProposalTimestamp[msg.sender] + throttle,
            "Proposal too soon"
        );

        proposalCount++;
        uint256 delay = IDAOConfig(daoConfig).votingDelay();

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            startTime: block.timestamp + delay,
            endTime: block.timestamp + delay + 3 days,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        lastProposalTimestamp[msg.sender] = block.timestamp;
        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(uint256 _proposalId, bool support) external {
        Proposal storage prop = proposals[_proposalId];
        require(block.timestamp >= prop.startTime, "Voting not started");
        require(block.timestamp <= prop.endTime, "Voting ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        hasVoted[_proposalId][msg.sender] = true;
        if (support) {
            prop.yesVotes++;
        } else {
            prop.noVotes++;
        }

        emit Voted(_proposalId, msg.sender, support);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage prop = proposals[_proposalId];
        require(block.timestamp > prop.endTime, "Voting not ended");
        require(!prop.executed, "Already executed");

        uint256 totalVotes = prop.yesVotes + prop.noVotes;
        uint256 quorum = IDAOConfig(daoConfig).quorumPercent();

        // Simplified quorum logic (assumes 100 = 100%)
        require((prop.yesVotes * 100) / totalVotes >= quorum, "Quorum not met");

        prop.executed = true;
        emit ProposalExecuted(_proposalId);

        // NOTE: Actual proposal execution logic (e.g., treasury transfer) would go here
    }
}

