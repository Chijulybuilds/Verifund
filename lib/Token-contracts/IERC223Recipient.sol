// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


/**  
 * @title ERC223 Token
 * @author Prince_Chinedu
 * @dev Interface for ERC223 token recipients
*/


/*//////////////////////////////////////////////////////////////
                            INTERFACES
////////////////////////////////////////////////////////////*/

interface IERC223Recipient {
    /**
     * @notice Handle the receipt of ERC223 tokens
     * @param _from Sender of the ERC223 tokens
     * @param _value Amount OF ERC233 received
     * @param _data Additional transfer data
     */
    function tokenReceived(
        address _from,
        uint256 _value,
        bytes calldata _data
    ) external;
}
