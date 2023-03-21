pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TokenDistribution {
    address public owner;
    uint256 public nextDepositId;
    mapping(uint256 => Record) public records;

    struct Record {
        address sender;
        uint256 amount;
        uint256 totalCount;
        uint256 remainCount;
        uint256 expiredTime;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function deposit(uint256 totalCount, uint256 expiredTime) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        records[nextDepositId] = Record(msg.sender, msg.value, totalCount, totalCount, expiredTime);
        nextDepositId++;
    }

    function claim(uint256 depositId, address recipient) public onlyOwner {
        require(msg.sender == owner, "Only the owner can claim.");
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(records[depositId].expiredTime >= block.timestamp, "Deposit expired.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        uint256 amount = records[depositId].amount / records[depositId].totalCount;
        records[depositId].remainCount--;
        payable(recipient).transfer(amount);
    }

    function claimToSender(uint256 depositId) public onlyOwner {
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(msg.sender == records[depositId].sender, "Only the sender can claim.");
        require(records[depositId].expiredTime < block.timestamp, "Only expired deposit can claim to sender.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        uint256 amount = records[depositId].amount / records[depositId].totalCount * records[depositId].remainCount;
        records[depositId].remainCount = 0;
        payable(msg.sender).transfer(amount);
    }
}


