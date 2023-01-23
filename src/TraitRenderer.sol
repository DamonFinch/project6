// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ITraitRenderer} from "./interfaces/ITraitRenderer.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
 */
contract TraitRenderer is ITraitRenderer {
    /// @dev tokenId to cre8ing start time (0 = not cre8ing).
    mapping(uint256 => mapping(uint256 => string)) internal traits;

    // constructor(string[][] memory _initialTraits) {
    //     for (uint256 i = 0; i < _initialTraits.length; ) {
    //         string[] memory traitArray = _initialTraits[i];
    //         for (uint256 j = 0; i < traitArray.length; ) {
    //             traits[i][j] = traitArray[j];
    //             unchecked {
    //                 j += 1;
    //             }
    //         }
    //         unchecked {
    //             i += 1;
    //         }
    //     }
    // }

    /// @notice Read trait for given tokenId
    /// @param _traitId id of trait
    /// @param _tokenId id of token
    function trait(uint256 _traitId, uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return traits[_traitId][_tokenId];
    }
}
