//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BankContract  is  ERC20, ERC20Burnable , AccessControl {
    bytes32 public constant MINTER_ROLE= keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IERC20 tokenA;
    IERC20 tokenB;
    
    struct customer{
        bool customerBool;
        address name;
        uint customerBalance;
        uint start;
        uint end;
    }

    struct bal{
        uint TABalance;
        uint TBBalance;
    }

    mapping (address => bal) public pool;
    address public banker;
    mapping(address => customer) public customerOfBank;
    uint public totalNoOfCustomers;
    uint public diff;
    uint i;
    uint public amtOfTokenA;
    uint public interest;

    constructor(address token1, address token2) ERC20("Token", "BT"){
        banker= msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        tokenA= IERC20(token1);
        tokenB= IERC20(token2);
    }

    modifier bankManager (){
        require(banker== msg.sender,"Not the banker");
        _;
    }
    
    function addCustomer(address _customer) bankManager public{
        require(customerOfBank[_customer].customerBool!= true, "Already a customer");
        customerOfBank[_customer].name = _customer;
        customerOfBank[_customer].customerBool = true;
        totalNoOfCustomers++;
    }

    function A2Atrasnfer(address _from, address _to, uint _amount) bankManager public {
        require(customerOfBank[_from].customerBool== true, "Not a Customer of Bank");
        require(customerOfBank[_to].customerBool== true, "Not a Customer of Bank");
        require(customerOfBank[_from].customerBalance>=_amount, "Insufficient Balance");
        customerOfBank[_to].customerBalance+= _amount;
        customerOfBank[_from].customerBalance -= _amount;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function withdrawMoney( address payable _to , uint _amount) bankManager public {
        require(customerOfBank[_to].customerBool== true, "Not a Customer of Bank");
        require(customerOfBank[_to].customerBalance>=_amount, "Insufficient Balance");
        _to.transfer(_amount);
        customerOfBank[_to].customerBalance-=_amount;
    }

    function closeAcc(address payable _to) bankManager public onlyRole(MINTER_ROLE){
        require(customerOfBank[_to].customerBool== true, "Not a Customer of Bank");
        _to.transfer(customerOfBank[_to].customerBalance);
        customerOfBank[_to].end= block.timestamp;
         diff= (customerOfBank[_to].end - customerOfBank[_to].start);
        i= customerOfBank[_to].customerBalance*diff* 5/100000000;
        _mint(_to, i);
        // transfer(_to, i);
        customerOfBank[_to].customerBalance=0;
        customerOfBank[_to].customerBool= false;
        customerOfBank[_to].name= payable(address(0));
        totalNoOfCustomers--;
    }

    function addMoney() public payable{
        require(customerOfBank[msg.sender].customerBool== true, "Not a Customer of Bank");
        customerOfBank[msg.sender].customerBalance += msg.value;
        customerOfBank[msg.sender].start= block.timestamp;
    }

    function addTokenA(  uint amt) public{
        require(customerOfBank[msg.sender].customerBool== true , "Not a customer of Bank");
        require(tokenA.allowance(msg.sender, address(this))>= amt, "Not allowed to spend this much");
        tokenA.transferFrom(msg.sender, address(this), amt);
        pool[msg.sender].TABalance+= amt;
    }

    function withdrawTokenA( uint amtOfTokenB) public{
        require(customerOfBank[msg.sender].customerBool== true , "Not a customer of Bank");
        amtOfTokenA= 80*amtOfTokenB/100;  // Limit= 80%
        require(tokenB.allowance(msg.sender, address(this))>= amtOfTokenB, "Not allowed to spend this much");
        tokenB.transferFrom(msg.sender, address(this), amtOfTokenB);
        tokenA.transfer(msg.sender, amtOfTokenA);
        interest+=(amtOfTokenA*156/10000); // amt of token A to return with interest @ 1.56%
        pool[msg.sender].TBBalance+=amtOfTokenB;
    }

    function retrevingTokenB() public{
        // tokenA.approve( address(this), (interest+amtOfTokenA));
        tokenA.transferFrom(msg.sender,address(this), (interest+amtOfTokenA));
        tokenB.transfer(msg.sender,(amtOfTokenA*100/80));
        pool[msg.sender].TBBalance=0;
    }

    function retrevingTokenA() public {
        tokenA.transfer(msg.sender, ( pool[msg.sender].TABalance+(interest/2)));
        _mint(msg.sender, 23);
        pool[msg.sender].TABalance=0;
    }
}
