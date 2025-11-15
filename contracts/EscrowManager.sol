// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Simple EscrowManager for freelance jobs
/// @notice Basic flow: employer creates -> funds -> assigns freelancer -> approves -> funds released
contract EscrowManager {
    struct Job {
        address employer;
        address freelancer;  // assigned freelancer
        uint256 amount;
        bool funded;
        bool approved;
        bool completed;
    }

    mapping(uint256 => Job) public jobs;
    mapping(uint256 => uint256) public pendingWithdrawals;

    event JobPublished(uint256 indexed jobId, uint256 amount);
    event JobAssigned(uint256 indexed jobId, address indexed freelancer);
    event JobApproved(uint256 indexed jobId, uint256 amount);
    event Withdrawn(uint256 indexed jobId, address indexed user, uint256 amount);

    modifier onlyEmployer(uint256 jobId) {
        require(msg.sender == jobs[jobId].employer, "Not job employer");
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Not assigned freelancer");
        _;
    }

    /// @notice Employer creates and funds the job
    function publishJob(uint256 jobId) external payable {
        Job storage j = jobs[jobId];
        require(j.employer == address(0), "Job already exists");
        j.employer = msg.sender;
        require(msg.value > 0, "No funds sent");
        j.amount = msg.value;
        j.funded = true;

        emit JobPublished(jobId, msg.value);
    }

    /// @notice Employer assigns a freelancer to the job
    function assignExecutor(uint256 jobId, address freelancer) external onlyEmployer(jobId) {
        Job storage j = jobs[jobId];
        require(j.freelancer == address(0), "Freelancer already assigned");
        require(freelancer != address(0), "Invalid freelancer address");

        j.freelancer = freelancer;
        emit JobAssigned(jobId, freelancer);
    }

    /// @notice Employer approves job and releases funds to freelancer
    function approveJob(uint256 jobId) external onlyEmployer(jobId) {
        Job storage j = jobs[jobId];
        require(j.funded, "Job not funded");
        require(j.amount > 0, "Nothing to release");
        require(j.freelancer != address(0), "Freelancer not assigned");

        j.approved = true;
        pendingWithdrawals[jobId] += j.amount;
        j.amount = 0;

        emit JobApproved(jobId, pendingWithdrawals[jobId]);
    }

    /// @notice Freelancer withdraws approved funds
    function withdraw(uint256 jobId) external onlyFreelancer(jobId) {
        Job storage j = jobs[jobId];
        require(j.approved, "Job not approved");
        uint256 amount = pendingWithdrawals[jobId];
        require(amount > 0, "No funds to withdraw");

        pendingWithdrawals[jobId] = 0;
        j.completed = true;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdrawn(jobId, msg.sender, amount);
    }

    /// @notice Fallback to reject accidental ETH
    receive() external payable {
        revert("Use publishJob() to fund");
    }
}
