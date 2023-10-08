// SPDX-License-Identifier: MIT
// Code by @0xGeeLoko

pragma solidity ^0.8.4;
// welcome to payroll distro
// verision: Based
// this contract is responsiple for managing bulk usdc tranfers
// to resolved subnames of a multisig resolved to a 2ld ens*
// unresolved names (subnames still resolved to multisig).. 
// ...are held in contract balance of manual payout after.. 
//...subname claim ny employee/contractor (resolved to other wallet)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//interfaces
/*
*ERC20
*/
interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract payrollDistro is Ownable, ReentrancyGuard {

    IERC20 USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913); //base USDC



    mapping(bytes32 => uint256) public payeeBalance;



    modifier isOverTotal (uint256[] calldata _amount) {
        uint256 totalAmount;
        for (uint256 i; i < _amount.length; ) {
            totalAmount += _amount[i];
            unchecked {
                i++;
            }
        }
        require(totalSupply() + totalAmount <= 10000, "max supply hit");
        _;
    }



    //ccip read owners of subnames
    function getResolvedAddress (bytes32 _to)
    internal
    returns (address)
    {
        
    }
    


    function tranferERC20(address _from, address _to, uint256 _amount) 
        internal 
    {
  
        bool transferred = USDC.transferFrom(_from, _to, (_amount * (1 * (10 ** 6))));
        require(transferred, "failed transfer"); 
    }



    function updateBalanceERC20(bytes32 payee, uint256 _amount) 
        internal 
    {
        payeeBalance[payee] += amount;
    }



    //**from employer
    //check if signer is approved on mutisig & and all signer approved
    //loop through namehashes for subnames in list
    //...for each subname resolved wallet on op/base to multisig(unclaimed) : store wall
    //...otherwise payout usdc amount to claimed subname wallet
    function doPayroll (bytes32[] calldata _to, uint256[] calldata _amount, address _multiSig)
    external
    isOverTotal(_amount)
    nonReentrant
    {
        require(_to.length == _amount.length, "payee/amount length mismatch");
        for (uint256 i; i < _to.length; ) {
            address payee = getResolvedAddress(_to[i]);
            
            if (payee == _multiSig) {
                //pay to this address for later claim
                tranferERC20(_multiSig, address(this), _amount[i]);
                //updatePayeeBalanceDue
                updateBalanceERC20(_to[i], _amount[i]);
            } else {
                //pay to resolved address wallet   
                tranferERC20(_multiSig, _to[i], _amount[i]);
            }

            unchecked {
                i++;
            }   
        }
    }



    // for payment not sent to final wallet
    function doClaimPayroll (bytes32 _to, address _multiSig)
    external
    nonReentrant
    {
        address payee = getResolvedAddress(_to);
    
        require(payee != _multiSig, 'unclaimed subname, cannot pay!');
        require(payeeBalance[payee] > 0, 'no outstandings!');

        uint256 payeeBalanceERC20 = payeeBalance[payee];
        payeeBalance[payee] = 0;

        (bool success, ) = payee.call{value: payeeBalanceERC20}(""); 
        require(success, "Transfer failed");

    }

}