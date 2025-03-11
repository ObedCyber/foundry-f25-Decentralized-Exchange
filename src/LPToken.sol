// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    address public owner;
    address public dexAddress;

    constructor(uint256 initialSupply) ERC20("LPToken", "LPT") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }
    modifier onlyDex(){
        require(msg.sender == dexAddress, "Only Dex can call this function");
        _;
    }
    function setDexAddress(address _dexAddress) external {
        require(msg.sender == owner, "Only Owner call this function");
        require(dexAddress == address(0), "Dex address already set");
        dexAddress = _dexAddress;
    }
    function mint(address to, uint amount) external onlyDex {
        _mint(to, amount);
    }

    // Burn function to destroy tokens
    function burn(address from, uint256 amount) external onlyDex{
        _burn(from, amount);
    }
}