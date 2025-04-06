// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowContract {
    address public jobContract;

    struct Escrow {
        address payable freelancer;
        uint256 amount;
        bool isFunded;
        bool isReleased;
    }

    mapping(uint256 => Escrow) public escrows;

    event FundsDeposited(uint256 jobId, address freelancer, uint256 amount);
    event FundsReleased(uint256 jobId, address freelancer, uint256 amount);

    modifier onlyJobContract() {
        require(msg.sender == jobContract, "Only JobContract can call this function");
        _;
    }

    constructor() {
        jobContract = msg.sender; // Set the deployer as JobContract (for simplicity)
    }

    function createEscrow(uint256 jobId, address payable freelancer) external payable onlyJobContract {
        require(!escrows[jobId].isFunded, "Escrow already funded");
        require(msg.value > 0, "Must send payment");

        escrows[jobId] = Escrow({
            freelancer: freelancer,
            amount: msg.value,
            isFunded: true,
            isReleased: false
        });

        emit FundsDeposited(jobId, freelancer, msg.value);
    }

    function releaseFunds(uint256 jobId) external onlyJobContract {
        Escrow storage escrow = escrows[jobId];

        require(escrow.isFunded, "Escrow not funded");
        require(!escrow.isReleased, "Funds already released");

        escrow.isReleased = true;
        escrow.freelancer.transfer(escrow.amount);

        emit FundsReleased(jobId, escrow.freelancer, escrow.amount);
    }
}
