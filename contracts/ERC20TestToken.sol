pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20('TEST ERC20 Token', "TEST") {
        _mint(msg.sender, initialSupply);
    }
}
