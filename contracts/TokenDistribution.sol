//"SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenDistribution is Initializable {

    uint8 constant RECORD_TYPE_RECIPIENTS = 1;
    uint8 constant RECORD_TYPE_ROOM = 2;
    uint64 public claimGasEvaluate = 220669;

    address public owner; // owner is the admin, and the contract creator.
    address public claimer; // claimer can do the claim
    address public withDrawer; // withDrawer can withDraw the
    uint256 public nextDepositId;
    uint16 public feeRate; // feeRate accuracy is 0.01%. the default is 1%, and 1% is 100.
    mapping(address => uint256) public feeRecord;
    address[] public feeTokens;


    mapping(uint256 => Record) public records;
    mapping(uint256 => mapping(address => ClaimInfo)) public claimInfos;
    bool private _locked;

    struct Record {
        address sender;
        address tokenAddress;
        uint8 recordType; // 1-To recipients 2-To room
        bool random;
        address[] recipients; // for type 1
        uint32 roomId; // for type 2
        uint256 amount;
        uint256 remainingAmount;
        uint32 totalCount;
        uint32 remainingCount;
        uint256 expiredTime;
    }

    struct ClaimInfo {
        address recipient;
        uint256 claimTime;
        uint256 amount;
    }

    event DepositEvent(
        uint256 depositId,
        address sender
    );


    function initialize(address _owner) public initializer {
        owner = _owner;
        claimer = _owner;
        withDrawer = _owner;
        feeRate = 100;
    }

    function setFeeRate(uint16 _feeRate) public onlyOwner {
        require(_feeRate <= 10000, "Fee rate must be between 0 and 10000.");
        feeRate = _feeRate;
    }

    function setClaimGas(uint64 _gasOfClaim) public onlyClaimer {
        claimGasEvaluate = _gasOfClaim;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    modifier onlyClaimer() {
        require(msg.sender == claimer || msg.sender == owner, "Only the contract owner or claimer can call this function.");
        _;
    }
    modifier onlyWithdrawer() {
        require(msg.sender == withDrawer || msg.sender == owner, "Only the contract owner or withdrawer can call this function.");
        _;
    }

    modifier noReentrant() {
        require(!_locked);
        _locked = true;
        _;
        _locked = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    function transferClaimShip(address newClaimer) public onlyOwner {
        claimer = newClaimer;
    }
    function transferWithdrawShip(address newWithdrawer) public onlyOwner {
        withDrawer = newWithdrawer;
    }

    function depositETHToRecipients(uint32 totalCount, address[] memory recipients, uint256 expiredTime, bool random, uint256 preGas) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        require(msg.value > preGas, "Invalid Deposit Data.");
        require(totalCount > 0, "Total count must be greater than zero.");
        require(recipients.length >= totalCount, "The number of recipients must be greater than or equal to the total count.");

        uint256 localGas = totalCount * claimGasEvaluate * tx.gasprice;
        require(preGas >= localGas, "The preset claim gas is not enough.");
        uint256 depositeValue = msg.value - preGas;

        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_RECIPIENTS, random, recipients, 0, depositeValue, depositeValue, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositETHToRoom(uint32 totalCount, uint32 roomId, uint256 expiredTime, bool random, uint256 preGas) public payable {
        require(msg.value > 0, "Deposit amount is zero.");
        require(msg.value > preGas, "Invalid Deposit Data.");
        require(totalCount > 0, "Total count must be greater than zero.");

        uint256 localGas = totalCount * claimGasEvaluate * tx.gasprice;
        require(preGas >= localGas, "The preset claim gas is not enough.");
        uint256 depositeValue = msg.value - preGas;

        records[nextDepositId] = Record(msg.sender, address(0), RECORD_TYPE_ROOM, random, new address[](0), roomId, depositeValue, depositeValue, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositErc20ToRecipients(uint256 totalValue, uint32 totalCount, address[] memory recipients, uint256 expiredTime, bool random, address tokenAddress) public payable {
        require(totalCount > 0, "Total count must be greater than zero.");
        require(recipients.length >= totalCount, "The number of recipients must be greater than or equal to the total count.");
        uint256 localGas = totalCount * claimGasEvaluate * tx.gasprice;
        require(msg.value >= localGas, "The preset claim gas is not enough.");

        ERC20 targetToken = ERC20(tokenAddress);
        uint256 allowanceHereFromSender = targetToken.allowance(msg.sender, address(this));
        require(allowanceHereFromSender >= totalValue, "The allowance of this contract must be greater than or equal to the sending value.");
        targetToken.transferFrom(msg.sender, address(this), totalValue);

        records[nextDepositId] = Record(msg.sender, tokenAddress, RECORD_TYPE_RECIPIENTS, random, recipients, 0, totalValue, totalValue, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function depositErc20ToRoom(uint256 totalValue, uint32 totalCount, uint32 roomId, uint256 expiredTime, bool random, address tokenAddress) public payable {
        require(totalValue > 0, "Deposit amount is zero.");
        require(totalCount > 0, "Total count must be greater than zero.");
        uint256 localGas = totalCount * claimGasEvaluate * tx.gasprice;
        require(msg.value >= localGas, "The preset claim gas is not enough.");

        ERC20 targetToken = ERC20(tokenAddress);
        uint256 allowanceHereFromSender = targetToken.allowance(msg.sender, address(this));
        require(allowanceHereFromSender >= totalValue, "The allowance of this contract must be greater than or equal to the sending value.");
        targetToken.transferFrom(msg.sender, address(this), totalValue);

        records[nextDepositId] = Record(msg.sender, tokenAddress, RECORD_TYPE_ROOM, random, new address[](0), roomId, totalValue, totalValue, totalCount, totalCount, expiredTime);
        emit DepositEvent(nextDepositId, msg.sender);
        nextDepositId++;
    }

    function claim(uint256 depositId, address recipient, uint256 amount) public onlyClaimer noReentrant {
        require(claimInfos[depositId][recipient].recipient == address(0), "Already claimed.");
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(records[depositId].expiredTime >= block.timestamp, "Deposit expired.");
        require(records[depositId].remainingCount > 0, "Invalid deposit remainingCount.");
        require(records[depositId].remainingAmount >= amount, "Invalid deposit amount.");
        if (records[depositId].remainingCount == 1) {
            amount = records[depositId].remainingAmount;
        }
        records[depositId].remainingCount--;
        records[depositId].remainingAmount -= amount;
        claimInfos[depositId][recipient].recipient = recipient;
        claimInfos[depositId][recipient].claimTime = block.timestamp;
        uint256 feeAmount = ((amount * feeRate) / 10000);
        if (records[depositId].tokenAddress == address(0)) {
            safeTransferETH(recipient, amount - feeAmount);
        } else {
            ERC20(records[depositId].tokenAddress).transfer(recipient, amount - feeAmount);
        }
        if (feeAmount > 0) {
            feeRecord[records[depositId].tokenAddress] += feeAmount;
            if (feeRecord[address(records[depositId].tokenAddress)] == feeAmount) {
                feeTokens.push(address(records[depositId].tokenAddress));
            }
        }
    }

    function withDrawAllTokens() public onlyWithdrawer noReentrant {
        require(feeTokens.length > 0, "No token can be withdraw");

        for (uint i = 0; i < feeTokens.length; i++) {
            address tokenAddress = feeTokens[i];
            if (tokenAddress == address(0)) {
                if (feeRecord[tokenAddress] > 0) {
                    payable(withDrawer).transfer(feeRecord[tokenAddress]);
                }
            } else {
                ERC20(tokenAddress).transfer(withDrawer, feeRecord[tokenAddress]);
            }
            delete feeRecord[tokenAddress];
        }
        delete feeTokens;
    }

    function listTokens() public view returns (address[] memory) {
        return feeTokens;
    }

    function claimToSender(uint256 depositId) public noReentrant {
        require(records[depositId].sender != address(0), "Invalid deposit ID.");
        require(msg.sender == records[depositId].sender, "Only the sender can claim.");
        require(records[depositId].expiredTime < block.timestamp, "Only expired deposit can claim to sender.");
        require(records[depositId].remainingCount > 0, "Invalid deposit remainingCount.");
        uint256 amount = records[depositId].remainingAmount;
        records[depositId].remainingAmount = 0;
        records[depositId].remainingCount = 0;
        if (records[depositId].tokenAddress == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            ERC20(records[depositId].tokenAddress).transfer(records[depositId].sender, amount);
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'Send eth failed.');
    }
}


