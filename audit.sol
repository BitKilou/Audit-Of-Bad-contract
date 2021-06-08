                        ///@notice This is the bad contract ! check below for an audited version.


   ///@dev Firstly we want to change this version of pragma;  
   /// We also want to import 2 different libraries SafeMath and Ownable;                 
 
 pragma solidity ^0.5.12;
 ///Change === pragma solidity 0.8.4;
 
contract Crowdsale {
   using SafeMath for uint256;
 
   address public owner; // the owner of the contract => 
   ///@dev I decided to get rid of this because we obtain it with the Ownable Lib
   address public escrow; // wallet to collect raised ETH => 
   ///@dev Here also, I decided to get rid of the address and implement a deposit function;
   uint256 public savedBalance = 0; // Total amount raised in ETH => 
   ///@dev In solidity no need to initiate when it is 0; We simply need to put : uint public savedBalance; => saves gas
   mapping (address => uint256) public balances; // Balances in incoming Ether =>
   ///@dev I decided to point it to a struct to gain gas and get rid of incoherent lines of code
 
   // Initialization
   function Crowdsale(address _escrow) public{
       ///@dev I replaced it by a simple deposit function;
       owner = tx.origin;
       ///@dev The tx.origin here is bad, if we used it, we need to use msg.sender; Or using Ownable Lib no need to specify !!
       escrow = _escrow;
   }
  
   ///@dev this function has no name... And it uses no safety requirements, we can imagine that there is a hardCap at 10ETH
   /// Also it is not recommended to use .send to transfer funds in SOlidity <0.8.0;
   /// If we needed to do it again this is the way i would maybe do it :

   /// function deposit() public {
     /// require(balances[msg.sender] =< 10 ether);
        ///  balances[msg.sender] = balances[msg.sender].add(msg.value);
        /// This line is repetitive we can remove it supposely savedBalance = savedBalance.add(msg.value);
            ///  payable(escrow).transfer(msg.value);
       ///}
   function() public {
       balances[msg.sender] = balances[msg.sender].add(msg.value);
       savedBalance = savedBalance.add(msg.value);
       escrow.send(msg.value);
   }
  
   // refund investisor
   ///@dev this function is a mess, I feel like we should erase it completely.
   ///@dev Here the refund system is not safe, a malicious smart contract could use a reentrancy attack.
   ///@dev This is the reason why we want to use a pullOverPush method;
   /// Also the address and uint could be simplified 
   /// The balances[payee] = 0; should be placed above payee send. 
   ///@dev a basic rule is to place state changes before any transfers to avoid risks !!!!!
   ///@dev the line savedBalance is here for nothing, we can also remove it. Since the balance is already stored in balances[msg.sender];

      function withdrawPayments() public{
       address payment = msg.sender;
       uint256 payment = balances[payee];
 
       payee.send(payment);
 
       savedBalance = savedBalance.sub(payment);
       balances[payee] = 0;
   }
}

 
                   /// AUDITED VERSION, this is how I would do this contract !!!!
                   /// I hope this version is not too far from original version of contract....

///@dev Firstly we need to put a license, then we will lock a version of solidity

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

///@dev we will then implement 2 librairies from openZeppelin to secure the contract and make it easier.
/// we will import the SafeMath and Ownable library

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
   
   contract AUDITEDCONTRACT is Ownable {
       
       using SafeMath for uint256;

       ///@dev using a basic struct to structure our need for the whitelisted addresses
       
       struct WhiteList {
           bool isAllowed;
           bool hasWithdrawn;
           uint amountInvested;
       }
       
       mapping(address => WhiteList) public whiteListed;

       ///@dev notice we set the owner as the deployer of the contract
       
       constructor() payable onlyOwner {
          
       }
       
       event hasDeposited(address from, uint amountDeposited);
       event isAllowedToPull(address isAllowed);
       event hasWithdrawn(address from, uint amountWithdrawn);

       ///@dev We make the deposit to escrow available to all, maybe to good idea to require that the deposited funds then have
       /// to be approved by the owner, otherwise the funds are stuck on the contract
       
       
       function depositToEscrow() public payable {
           
           whiteListed[msg.sender].amountInvested = whiteListed[msg.sender].amountInvested.add(msg.value);
           
           emit hasDeposited(msg.sender, msg.value);
       }

       ///@dev We set it so that the owner give approval or not to withdraw the funds
       
       function allowToPull(address _allowedAdd) public onlyOwner {
           
           whiteListed[_allowedAdd].isAllowed = true;
           
           emit isAllowedToPull(_allowedAdd);
       }

       ///@dev We decided to use the pullOverPush method, which is safer 
       /// We need to make sur that, the user is allowed to withdraw, hasn't withdrawn already and that the amount is lower then what he invested
       /// Then we set his balance to 0 to avoid any reetrancy attacks and set his state to hasWithdrawn == true;
       
       function withdrawAll() public payable {
           
           uint amoutToClaim = whiteListed[msg.sender].amountInvested;
           
           require(whiteListed[msg.sender].isAllowed == true);
           require(whiteListed[msg.sender].hasWithdrawn = false);
           require(whiteListed[msg.sender].amountInvested >= msg.value);
           
           whiteListed[msg.sender].amountInvested = 0;
           
           payable(msg.sender).transfer(amoutToClaim);
           
           whiteListed[msg.sender].hasWithdrawn = true;
           
           emit hasWithdrawn(msg.sender, msg.value);
           
       }

       ///@dev a simple getBalance function to make sur everything is working fine
       
        function getBalance() public view returns(uint) {
           return address(this).balance;
       }
       
   }