//"SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenDistribution is Initializable {

    uint8 constant RECORD_TYPE_RECIPIENTS = 1;
    uint8 constant RECORD_TYPE_ROOM = 2;

    address public owner;
    uint256 public nextDepositId;
    mapping(uint256 => Record) public records;
    mapping(uint256 => mapping(address => ClaimInfo)) public claimInfos;
    mapping(uint256 => mapping(address => bool)) public depositRecipients;

    struct Record {
        address sender;
        address tokenAddress;
        uint8 recordType; // 1-To recipients 2-To room
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

    event DepositEvent(
        uint256 depositId,
        address sender
    );


    function initialize(address _owner) public initializer {
        owner = _owner;
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
        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_RECIPIENTS, 0, msg.value, totalCount, totalCount, expiredTime);
        for(uint i = 0; i < recipients.length; i++) {
            depositRecipients[nextDepositId][recipients[i]] = true;
        }
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositETHToRoom(uint32 totalCount, uint32 roomId, uint256 expiredTime) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        require(totalCount > 0, "Total count must be greater than zero.");
        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_ROOM, roomId, msg.value, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositErc20ToRecipients(uint256 totalValue, uint32 totalCount, address[] memory recipients, uint256 expiredTime, address tokenAddress) public {
        require(totalCount > 0, "Total count must be greater than zero.");
        require(recipients.length >= totalCount, "The number of recipients must be greater than or equal to the total count.");
        
        ERC20 targetToken = ERC20(tokenAddress);
        uint256 allowanceHereFromSender = targetToken.allowance(msg.sender, address(this));
        require(allowanceHereFromSender >= totalValue, "The allowance of this contract must be greater than or equal to the sending value.");
        targetToken.transferFrom(msg.sender, address(this), totalValue);

        records[nextDepositId] = Record(msg.sender, tokenAddress, RECORD_TYPE_RECIPIENTS, 0, totalValue, totalCount, totalCount, expiredTime);
        for(uint i = 0; i < recipients.length; i++) {
            depositRecipients[nextDepositId][recipients[i]] = true;
        }
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositErc20ToRoom(uint256 totalValue, uint32 totalCount, uint32 roomId, uint256 expiredTime, address tokenAddress) public {
        require(totalValue > 0, "Deposit amount is zero.");
        require(totalCount > 0, "Total count must be greater than zero.");

        ERC20 targetToken = ERC20(tokenAddress);
        uint256 allowanceHereFromSender = targetToken.allowance(msg.sender, address(this));
        require(allowanceHereFromSender >= totalValue, "The allowance of this contract must be greater than or equal to the sending value.");
        targetToken.transferFrom(msg.sender, address(this), totalValue);

        records[nextDepositId] = Record(msg.sender, tokenAddress, RECORD_TYPE_ROOM, roomId, totalValue, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function claim(uint256 depositId, address recipient) public onlyOwner {
        require(msg.sender == owner, "Only the owner can claim.");
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(records[depositId].expiredTime >= block.timestamp, "Deposit expired.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        require(claimInfos[depositId][recipient].recipient == address(0), "Already claimed.");
        uint256 amount = records[depositId].amount / records[depositId].totalCount;
        if (records[depositId].recordType == RECORD_TYPE_RECIPIENTS) {
            require(depositRecipients[depositId][recipient] == true, "Invalid recipient.");
            if (records[depositId].tokenAddress == address(0)) {
                payable(recipient).transfer(amount);
            } else {
                ERC20(records[depositId].tokenAddress).transfer(recipient, amount);
            }
        } else if (records[depositId].recordType == RECORD_TYPE_ROOM) {
            if (records[depositId].tokenAddress == address(0)) {
                payable(recipient).transfer(amount);
            } else {
                ERC20(records[depositId].tokenAddress).transfer(recipient, amount);
            }
        }
        records[depositId].remainCount--;
        claimInfos[depositId][recipient].recipient = recipient;
        claimInfos[depositId][recipient].claimTime = block.timestamp;
    }

    function claimToSender(uint256 depositId) public {
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(msg.sender == records[depositId].sender, "Only the sender can claim.");
        require(records[depositId].expiredTime < block.timestamp, "Only expired deposit can claim to sender.");
        require(records[depositId].remainCount > 0, "Invalid deposit remainCount.");
        uint256 amount = records[depositId].amount / records[depositId].totalCount * records[depositId].remainCount;
        if (records[depositId].tokenAddress == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            ERC20(records[depositId].tokenAddress).transfer(records[depositId].sender, amount);
        }
        records[depositId].remainCount = 0;
    }
}


