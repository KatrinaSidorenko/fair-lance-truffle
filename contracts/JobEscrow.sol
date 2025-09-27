// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract JobEscrow {
    enum JobStatus { Open, Assigned, Submitted, Approved, Refunded }

    event FreelancerAssigned(address indexed freelancer, string jobId);
    event WorkSubmitted(address indexed freelancer, string submissionId);
    event Approved(address indexed freelancer, string jobId, uint amount);
    event Refunded(address indexed client, string jobId, uint amount);

    address public client;
    address public freelancer;
    uint public amount;
    JobStatus public status;

    string public jobId;
    string public submissionId;
    bool public fundsReleased;

    modifier onlyClient() {
        require(msg.sender == client, "Only client");
        _;
    }

    modifier onlyFreelancer() {
        require(msg.sender == freelancer, "Only freelancer");
        _;
    }

    constructor(address _client, string memory _jobId) payable {
        client = _client;
        amount = msg.value;
        status = JobStatus.Open;
        fundsReleased = false;
        jobId = _jobId;
    }

    function assignFreelancer(address _freelancer) external onlyClient {
        require(status == JobStatus.Open, "Job not open");
        freelancer = _freelancer;
        status = JobStatus.Assigned;
        emit FreelancerAssigned(freelancer, jobId);
    }

    function submitWork(string memory _submissionId) external onlyFreelancer {
        require(status == JobStatus.Assigned, "Not assigned");
        submissionId = _submissionId;
        status = JobStatus.Submitted;
        emit WorkSubmitted(freelancer, submissionId);
    }

    function approveWork() external onlyClient {
        require(status == JobStatus.Submitted, "Not submitted");
        require(!fundsReleased, "Funds already released");
        fundsReleased = true;
        status = JobStatus.Approved;
        payable(freelancer).transfer(amount);
        emit Approved(freelancer, jobId, amount);
    }

    function refundClient() external onlyClient {
        require(status == JobStatus.Open || status == JobStatus.Assigned, "Refund not allowed now");
        require(!fundsReleased, "Funds already released");
        fundsReleased = true;
        status = JobStatus.Refunded;
        payable(client).transfer(amount);
        emit Refunded(client, jobId, amount);
    }
}
