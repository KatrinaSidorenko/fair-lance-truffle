// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./JobEscrow.sol";

contract JobFactory {
    event JobCreated(address indexed jobAddress, address indexed client, string jobId, uint amount);

    struct Job {
        string jobId;
        address jobAddress;
    }

    Job[] public allJobs;

    function createJob(string memory jobId) external payable returns (address) {
        require(msg.value > 0, "Must fund job");
        JobEscrow job = new JobEscrow{value: msg.value}(msg.sender, jobId);
        allJobs.push(Job({
            jobId: jobId,
            jobAddress: address(job)
        }));
        emit JobCreated(address(job), msg.sender, jobId, msg.value);
        return address(job);
    }

    function getAllJobs() external view returns (address[] memory, string[] memory) {
        address[] memory jobAddresses = new address[](allJobs.length);
        string[] memory jobIds = new string[](allJobs.length);

        for (uint i = 0; i < allJobs.length; i++) {
            jobAddresses[i] = allJobs[i].jobAddress;
            jobIds[i] = allJobs[i].jobId;
        }

        return (jobAddresses, jobIds);
    }
}
