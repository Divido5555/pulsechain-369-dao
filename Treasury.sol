// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IGovernance {
    function isProposalApproved(uint256 proposalId) external view returns (bool);
}

contract Treasury {
    enum AccessMode { DAO_ONLY, MULTISIG_ONLY, HYBRID }
    AccessMode public accessMode;

    address public founder;
    address public governanceContract;
    address public multiSigWallet;

    struct ProposalWithdrawal {
        address payable recipient;
        uint256 amount;
        bool executed;
    }

    mapping(uint256 => ProposalWithdrawal) public withdrawals;

    modifier onlyFounder() {
        require(msg.sender == founder, "Not founder");
        _;
    }

    modifier onlyAuthorized(uint256 proposalId) {
        if (accessMode == AccessMode.DAO_ONLY) {
            require(msg.sender == governanceContract, "DAO-only access");
        } else if (accessMode == AccessMode.MULTISIG_ONLY) {
            require(msg.sender == multiSigWallet, "Multisig-only access");
        } else if (accessMode == AccessMode.HYBRID) {
            require(
                msg.sender == governanceContract || msg.sender == multiSigWallet,
                "Hybrid requires DAO or MultiSig"
            );
            require(
                IGovernance(governanceContract).isProposalApproved(proposalId),
                "Hybrid: proposal not approved"
            );
        }
        _;
    }

    constructor() {
        founder = msg.sender;
    }

    receive() external payable {}

    function setGovernanceContract(address _addr) external onlyFounder {
        governanceContract = _addr;
    }

    function setMultiSigWallet(address _addr) external onlyFounder {
        multiSigWallet = _addr;
    }

    function setAccessMode(uint8 mode) external onlyFounder {
        require(mode <= uint8(AccessMode.HYBRID), "Invalid mode");
        accessMode = AccessMode(mode);
    }

    function queueWithdrawal(uint256 proposalId, address payable to, uint256 amount)
        external
        onlyAuthorized(proposalId)
    {
        require(!withdrawals[proposalId].executed, "Already executed");
        withdrawals[proposalId] = ProposalWithdrawal({
            recipient: to,
            amount: amount,
            executed: false
        });
    }

    function executeWithdrawal(uint256 proposalId) external onlyAuthorized(proposalId) {
        ProposalWithdrawal storage w = withdrawals[proposalId];
        require(!w.executed, "Already executed");
        require(address(this).balance >= w.amount, "Insufficient funds");

        w.executed = true;
        w.recipient.transfer(w.amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
