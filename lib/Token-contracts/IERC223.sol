// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**  
 * @title ERC223 Token
 * @author Prince_Chinedu
 * @dev Interface for ERC223 token
*/

interface IERC223 {
    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    event Approval(
        address indexed owner,  
        address indexed spender,
        uint256 value
    );

    /*//////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);   // the brand name of token

    function symbol() external view returns (string memory); // the brand symbol

    function decimals() external view returns (uint8); // the number of zeros after the amount

    /*//////////////////////////////////////////////////////////////
                             ERC223 LOGIC
    //////////////////////////////////////////////////////////////*/

    // reads the total supply of token in circulation
    function totalSupply() external view returns (uint256);  

    // reads the balance of a specific address
    function balanceOf(address owner) external view returns (uint256); 

    function transfer(
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                         OPTIONAL ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}