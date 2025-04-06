// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowContract.sol";

contract JobContract {
    EscrowContract public escrow;

    enum JobStatus { Open, Assigned, Completed }

    struct Job {
        string description;
        uint256 budget;
        address client;
        address freelancer;
        JobStatus status;
    }

    uint256 public jobCounter;
    mapping(uint256 => Job) public jobs;

    event JobCreated(uint256 jobId, address client, string description, uint256 budget);
    event JobAssigned(uint256 jobId, address freelancer);
    event JobCompleted(uint256 jobId);

    constructor(address escrowAddress) {
        escrow = EscrowContract(payable(escrowAddress));
    }

    function createJob(string calldata description, uint256 budget) external {
        uint256 jobId = ++jobCounter;

        jobs[jobId] = Job({
            description: description,
            budget: budget,
            client: msg.sender,
            freelancer: address(0),
            status: JobStatus.Open
        });

        emit JobCreated(jobId, msg.sender, description, budget);
    }

    function assignFreelancer(uint256 jobId, address freelancer) external payable {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can assign");
        require(job.status == JobStatus.Open, "Job not open");
        require(msg.value == job.budget, "Incorrect payment");

        job.freelancer = freelancer;
        job.status = JobStatus.Assigned;

        // Send payment to EscrowContract
        (bool sent, ) = address(escrow).call{value: msg.value}(
            abi.encodeWithSignature("createEscrow(uint256,address)", jobId, freelancer)
        );
        require(sent, "Escrow funding failed");

        emit JobAssigned(jobId, freelancer);
    }

    function markJobCompleted(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can complete");
        require(job.status == JobStatus.Assigned, "Job not assigned");

        job.status = JobStatus.Completed;
        escrow.releaseFunds(jobId);

        emit JobCompleted(jobId);
    }
}
