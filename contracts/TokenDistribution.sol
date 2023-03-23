pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TokenDistribution {

    uint8 constant RECORD_TYPE_RECIPIENTS = 1;
    uint8 constant RECORD_TYPE_ROOM = 2;

    address public owner;
    uint256 public nextDepositId;
    mapping(uint256 => Record) public records;
    mapping(uint256 => mapping(address => ClaimInfo)) public claimInfos;

    struct Record {
        address sender;
        address tokenAddress;
        uint8 recordType; // 1-To recipients 2-To room
        address[] recipients; // for type 1
        uint32 roomId; // for type 2
        uint256 amount;
        uint32 totalCount;
        uint32 remainCount;
        uint256 expiredTime;
    }

    struct ClaimInfo {
        address recipient;
        uint256 claimTime;
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

    function depositETHToRecipients(uint32 totalCount, address[] memory recipients, uint256 expiredTime) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        require(totalCount > 0, "Total count must be greater than zero.");
        require(recipients.length >= totalCount, "The number of recipients must be greater than or equal to the total count.");
        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_RECIPIENTS, recipients, 0, msg.value, totalCount, totalCount, expiredTime);
        nextDepositId++;
    }

    function depositETHToRoom(uint32 totalCount, uint32 roomId, uint256 expiredTime) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        require(totalCount > 0, "Total count must be greater than zero.");
        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_ROOM, new address[](0), roomId, msg.value, totalCount, totalCount, expiredTime);
        nextDepositId++;
    }

    function depositErc20ToRecipients(uint32 totalCount, address[] memory recipients, uint256 expiredTime, address tokenAddress) public {
    }

    function depositErc20ToRoom(uint32 totalCount, uint32 roomId, uint256 expiredTime, address tokenAddress) public {
    }

    function claim(uint256 depositId, address recipient) public onlyOwner {
        require(msg.sender == owner, "Only the owner can claim.");
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(records[depositId].expiredTime >= block.timestamp, "Deposit expired.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        require(claimInfos[depositId][recipient].recipient == address(0), "Already claimed.");
        if (records[depositId].recordType == RECORD_TYPE_RECIPIENTS) {
            require(isInArray(recipient, records[depositId].recipients), "Invalid recipient.");
            if (records[depositId].tokenAddress == address(0)) {
                uint256 amount = records[depositId].amount / records[depositId].totalCount;
                records[depositId].remainCount--;
                claimInfos[depositId][recipient].recipient = recipient;
                claimInfos[depositId][recipient].claimTime = block.timestamp;
                payable(recipient).transfer(amount);
            } else {
                // todo
            }
        } else if (records[depositId].recordType == RECORD_TYPE_ROOM) {
            if (records[depositId].tokenAddress == address(0)) {
                uint256 amount = records[depositId].amount / records[depositId].totalCount;
                records[depositId].remainCount--;
                claimInfos[depositId][recipient].recipient = recipient;
                claimInfos[depositId][recipient].claimTime = block.timestamp;
                payable(recipient).transfer(amount);
            } else {
                // todo
            }
        }
    }

    function claimToSender(uint256 depositId) public {
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(msg.sender == records[depositId].sender, "Only the sender can claim.");
        require(records[depositId].expiredTime < block.timestamp, "Only expired deposit can claim to sender.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        uint256 amount = records[depositId].amount / records[depositId].totalCount * records[depositId].remainCount;
        if (records[depositId].tokenAddress == address(0)) {
            records[depositId].remainCount = 0;
            payable(msg.sender).transfer(amount);
        } else {
            // todo
        }
    }

    function isInArray(address addr, address[] memory array) private pure returns(bool) {
        for(uint i=  0; i < array.length; i++) {
            if(array[i] == addr) {
                return true;
            }
        }
        return false;
    }
}


