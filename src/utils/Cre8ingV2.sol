// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ICre8ingV2} from "../interfaces/ICre8ingV2.sol";
import {ICre8ors} from "../interfaces/ICre8ors.sol";
import {IERC721Drop} from "../interfaces/IERC721Drop.sol";
import {Cre8orsAccessControl} from "../utils/Cre8orsAccessControl.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
 */
/// @dev inspiration: https://etherscan.io/address/0x23581767a106ae21c074b2276d25e5c3e136a68b#code
contract Cre8ingV2 is ICre8ingV2, Cre8orsAccessControl {
    /// @notice Whether cre8ing is currently allowed.
    /// @dev If false then cre8ing is blocked, but uncre8ing is always allowed.
    mapping(address => bool) public cre8ingOpen;
    /// @dev tokenId to cre8ing start time (0 = not cre8ing).
    mapping(address => mapping(uint256 => uint256)) internal cre8ingStarted;
    /// @dev Cumulative per-token cre8ing, excluding the current period.
    mapping(address => mapping(uint256 => uint256)) internal cre8ingTotal;

    /////////////////////////////////////////////////
    /// CRE8ING
    /////////////////////////////////////////////////

    /// @notice Toggles cre8ing status for multiple tokens.
    /// @param _target The target address.
    /// @param tokenIds Array of token IDs to toggle.
    function toggleCre8ingTokens(
        address _target,
        uint256[] calldata tokenIds
    ) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _toggleCre8ingToken(_target, tokenIds[i]);
        }
    }

    /// @notice Returns the length of time, in seconds, that the CRE8OR has cre8ed.
    /// @dev Cre8ing is tied to a specific CRE8OR, not to the owner, so it doesn't
    ///     reset upon sale.
    /// @param _target The target address for the CRE8OR.
    /// @param tokenId The token ID to query.
    /// @return cre8ing Whether the CRE8OR is currently cre8ing. MAY be true with
    ///     zero current cre8ing if in the same block as cre8ing began.
    /// @return current Zero if not currently cre8ing, otherwise the length of time
    ///     since the most recent cre8ing began.
    /// @return total Total period of time for which the CRE8OR has cre8ed across
    ///     its life, including the current period.
    function cre8ingPeriod(
        address _target,
        uint256 tokenId
    ) external view returns (bool cre8ing, uint256 current, uint256 total) {
        uint256 start = cre8ingStarted[_target][tokenId];
        if (start != 0) {
            cre8ing = true;
            current = block.timestamp - start;
        }
        total = current + cre8ingTotal[_target][tokenId];
    }

    /// @notice Returns the array of staked token IDs.
    /// @param _target The target address.
    /// @return stakedTokens Array of staked token IDs.
    function cre8ingTokens(
        address _target
    ) external view returns (uint256[] memory stakedTokens) {
        uint256 size = ICre8ors(_target)._lastMintedTokenId();
        stakedTokens = new uint256[](size);
        for (uint256 i = 1; i < size + 1; ++i) {
            uint256 start = cre8ingStarted[_target][i];
            if (start != 0) {
                stakedTokens[i - 1] = i;
            }
        }
    }

    /// @notice Get the cre8ing start time for a token.
    /// @param _target The target address.
    /// @param tokenId The token ID to query.
    /// @return The cre8ing start time for the token.
    function getCre8ingStarted(
        address _target,
        uint256 tokenId
    ) external view returns (uint256) {
        return cre8ingStarted[_target][tokenId];
    }

    /////////////////////////////////////////////////
    /// Admin
    /////////////////////////////////////////////////

    /// @notice Toggles the `cre8ingOpen` flag.
    /// @param _target The target address.
    /// @param open Boolean value to open or close cre8ing.
    function setCre8ingOpen(
        address _target,
        bool open
    ) external onlyAdmin(_target) {
        cre8ingOpen[_target] = open;
    }

    /// @notice Initialize staking for a set of tokens.
    /// @param _target The target address.
    /// @param _tokenIds Array of token IDs.
    function inializeStaking(
        address _target,
        uint256[] memory _tokenIds
    ) external onlyMinterOrAdmin(_target) {
        for (uint256 i = 0; i < _tokenIds.length; ) {
            // start staking
            _enterWarehouse(_target, _tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Admin-only ability to expel a CRE8OR from the Warehouse.
    /// @dev As most sales listings use off-chain signatures it's impossible to
    ///     detect someone who has cre8ed and then deliberately undercuts the floor
    ///     price in the knowledge that the sale can't proceed. This function allows for
    ///     monitoring of such practices and expulsion if abuse is detected, allowing
    ///     the undercutting CRE8OR to be sold on the open market. Since OpenSea uses
    ///     isApprovedForAll() in its pre-listing checks, we can't block by that means
    ///     because cre8ing would then be all-or-nothing for all of a particular owner's
    ///     CRE8OR.
    /// @param _target The target address.
    /// @param tokenId The token ID to expel.
    function expelFromWarehouse(
        address _target,
        uint256 tokenId
    ) external onlyAdmin(_target) {
        if (cre8ingStarted[_target][tokenId] == 0) {
            revert CRE8ING_NotCre8ing(_target, tokenId);
        }
        cre8ingTotal[_target][tokenId] +=
            block.timestamp -
            cre8ingStarted[_target][tokenId];
        cre8ingStarted[_target][tokenId] = 0;
        emit Uncre8ed(_target, tokenId);
        emit Expelled(_target, tokenId);
    }

    /////////////////////////////////////////////////
    /// INTERNAL
    /////////////////////////////////////////////////

    /// @notice Enter a CRE8OR into the warehouse.
    /// @param _target The target address.
    /// @param tokenId The token ID to enter.
    function _enterWarehouse(address _target, uint256 tokenId) internal {
        if (!cre8ingOpen[_target]) {
            revert Cre8ing_Cre8ingClosed();
        }
        cre8ingStarted[_target][tokenId] = block.timestamp;
        emit Locked(tokenId);
    }

    /// @notice Exit a CRE8OR from the warehouse.
    /// @param _target The target address.
    /// @param tokenId The token ID to exit.
    function _leaveWarehouse(address _target, uint256 tokenId) internal {
        uint256 start = cre8ingStarted[_target][tokenId];
        cre8ingTotal[_target][tokenId] += block.timestamp - start;
        cre8ingStarted[_target][tokenId] = 0;
        emit Uncre8ed(_target, tokenId);
    }

    /// @notice Toggle cre8ing status for a specific token.
    /// @param _target The target address.
    /// @param tokenId The token ID to toggle.
    function _toggleCre8ingToken(
        address _target,
        uint256 tokenId
    ) internal onlyApprovedOrOwner(_target, tokenId) {
        uint256 start = cre8ingStarted[_target][tokenId];
        if (start == 0) {
            _enterWarehouse(_target, tokenId);
        } else {
            _leaveWarehouse(_target, tokenId);
        }
    }

    /////////////////////////////////////////////////
    /// MODIFIERS
    /////////////////////////////////////////////////

    /// @notice Modifier for only approved or owner access.
    /// @param _target The target address.
    /// @param tokenId The token ID to verify.
    modifier onlyApprovedOrOwner(address _target, uint256 tokenId) {
        if (
            ICre8ors(_target).ownerOf(tokenId) != msg.sender &&
            ICre8ors(_target).getApproved(tokenId) != msg.sender
        ) {
            revert IERC721Drop.Access_MissingOwnerOrApproved();
        }

        _;
    }
}
