//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20{
    constructor() ERC20("TokenB","TB"){}

    function mint(uint amt) public{
        _mint(msg.sender, amt*10**decimals());
    }
    
 }
