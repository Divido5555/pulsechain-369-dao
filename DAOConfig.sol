// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract DAOConfig {
    enum DAOMode { FAMILY, COMPANY, TOWN }

    address public founder;
    address public token;
    address public governance;
    address public treasury;
    address public saftRegistry;

    string public daoName;
    string public daoURI;

    DAOMode public mode;
    uint256 public voteFrequencyDays;
    uint256 public votingDelay;
    uint256 public quorumPercent;
    uint256 public founderUnlockTime;

    bool public votingEnabled;

    event Initialized(address token, address governance, address treasury, address saftRegistry);
    event VotingEnabled();
    event SAFTRegistryUpdated(address newRegistry);
    event BootstrapCompleted();

    modifier onlyFounder() {
        require(msg.sender == founder, "Not founder");
        _;
    }

    constructor(string memory _daoName, string memory _daoURI, DAOMode _mode) {
        founder = msg.sender;
        daoName = _daoName;
        daoURI = _daoURI;
        mode = _mode;
        votingEnabled = false;
    }

    function initialize(
        address _token,
        address _governance,
        address _treasury,
        address _saftRegistry,
        uint256 _voteFrequencyDays,
        uint256 _votingDelay,
        uint256 _quorumPercent,
        uint256 _founderUnlockTime
    ) external onlyFounder {
        require(!votingEnabled, "Already initialized");
        require(_voteFrequencyDays >= 1 && _voteFrequencyDays <= 365, "Invalid vote frequency");

        token = _token;
        governance = _governance;
        treasury = _treasury;
        saftRegistry = _saftRegistry;

        voteFrequencyDays = _voteFrequencyDays;
        votingDelay = _votingDelay;
        quorumPercent = _quorumPercent;
        founderUnlockTime = _founderUnlockTime;

        emit Initialized(_token, _governance, _treasury, _saftRegistry);
    }

    function enableVoting() external onlyFounder {
        require(!votingEnabled, "Voting already enabled");
        votingEnabled = true;
        emit VotingEnabled();
    }

    function updateSAFTRegistry(address _newRegistry) external onlyFounder {
        require(!votingEnabled, "Voting is active");
        saftRegistry = _newRegistry;
        emit SAFTRegistryUpdated(_newRegistry);
    }

    function completeBootstrap() external onlyFounder {
        founderUnlockTime = block.timestamp;
        emit BootstrapCompleted();
    }
