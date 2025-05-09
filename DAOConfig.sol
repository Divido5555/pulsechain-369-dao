// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract DAOConfig {
    enum DAOMode { FAMILY, COMPANY, TOWN }
    DAOMode public daoMode;

    address public founder;
    address public daoToken;
    address public treasury;
    bool public votingEnabled;
    uint256 public votingEnableTime;
    uint256 public requiredTokenDeposit;

    modifier onlyFounder() {
        require(msg.sender == founder, "Not founder");
        _;
    }

    constructor(DAOMode _mode) {
        founder = msg.sender;
        daoMode = _mode;
        votingEnabled = false;
    }

    function initialize(address _token, address _treasury) external onlyFounder {
        daoToken = _token;
        treasury = _treasury;
        requiredTokenDeposit = IERC20(_token).totalSupply();
    }

    function enableVoting() external onlyFounder {
        require(!votingEnabled, "Voting already enabled");
        require(IERC20(daoToken).balanceOf(treasury) == requiredTokenDeposit, "Treasury does not hold all tokens");

        votingEnabled = true;
        votingEnableTime = block.timestamp;
    }
}
