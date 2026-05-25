// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


/**  
 * @title ERC223 Token
 * @author Prince_Chinedu
 * @dev Contract showing ownership of contract
*/


/*//////////////////////////////////////////////////////////////
                            OWNABLE
//////////////////////////////////////////////////////////////*/

abstract contract Ownable {
    error NotOwner();
    error InvalidOwner();
    
    /* the owner is being the deployer of the contract */
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert InvalidOwner();

        owner = initialOwner;

        emit OwnershipTransferred(address(0), initialOwner);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidOwner();

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }
}
