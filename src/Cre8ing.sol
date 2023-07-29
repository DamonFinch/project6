// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Cre8iveAdmin} from "./Cre8iveAdmin.sol";
import {ICre8ing} from "./interfaces/ICre8ing.sol";
import {IAfterLeaveWarehouseHook} from "./interfaces/IAfterLeaveWarehouseHook.sol";
import {IBeforeLeaveWarehouseHook} from "./interfaces/IBeforeLeaveWarehouseHook.sol";
import {ICre8ingHooks} from "./interfaces/ICre8ingHooks.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
 */
/// @dev inspiration: https://etherscan.io/address/0x23581767a106ae21c074b2276d25e5c3e136a68b#code
contract Cre8ing is Cre8iveAdmin, ICre8ing, ICre8ingHooks {

    /// @dev Mapping of hook types to their respective contract addresses.
    mapping(HookType => address) public hooks;
    /// @dev tokenId to cre8ing start time (0 = not cre8ing).
    mapping(uint256 => uint256) internal cre8ingStarted;
    /// @dev Cumulative per-token cre8ing, excluding the current period.
    mapping(uint256 => uint256) internal cre8ingTotal;

    /// @dev MUST only be modified by safeTransferWhileCre8ing(); if set to 2 then
    ///     the _beforeTokenTransfer() block while cre8ing is disabled.
    uint256 internal cre8ingTransfer = 1;

    event UpdatedHook(address indexed setter, HookType hookType, address indexed hookAddress);


    constructor(address _initialOwner) Cre8iveAdmin(_initialOwner) {}

    /// @notice Whether cre8ing is currently allowed.
    /// @dev If false then cre8ing is blocked, but uncre8ing is always allowed.
    bool public cre8ingOpen = false;

    /// @notice Returns the length of time, in seconds, that the CRE8OR has cre8ed.
    /// @dev Cre8ing is tied to a specific CRE8OR, not to the owner, so it doesn't
    ///     reset upon sale.
    /// @return cre8ing Whether the CRE8OR is currently cre8ing. MAY be true with
    ///     zero current cre8ing if in the same block as cre8ing began.
    /// @return current Zero if not currently cre8ing, otherwise the length of time
    ///     since the most recent cre8ing began.
    /// @return total Total period of time for which the CRE8OR has cre8ed across
    ///     its life, including the current period.
    function cre8ingPeriod(
        uint256 tokenId
    ) external view returns (bool cre8ing, uint256 current, uint256 total) {
        uint256 start = cre8ingStarted[tokenId];
        if (start != 0) {
            cre8ing = true;
            current = block.timestamp - start;
        }
        total = current + cre8ingTotal[tokenId];
    }

    /// @notice Toggles the `cre8ingOpen` flag.
    function setCre8ingOpen(
        bool open
    ) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
        cre8ingOpen = open;
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
    function expelFromWarehouse(
        uint256 tokenId
    ) external onlyRole(EXPULSION_ROLE) {
        if (cre8ingStarted[tokenId] == 0) {
            revert CRE8ING_NotCre8ing(tokenId);
        }
        cre8ingTotal[tokenId] += block.timestamp - cre8ingStarted[tokenId];
        cre8ingStarted[tokenId] = 0;
        emit Uncre8ed(tokenId);
        emit Expelled(tokenId);
    }

    /// @notice put a CRE8OR in the warehouse
    /// @param tokenId token to put in the Warehouse
    function enterWarehouse(uint256 tokenId) internal {
        if (!cre8ingOpen) {
            revert Cre8ing_Cre8ingClosed();
        }
        cre8ingStarted[tokenId] = block.timestamp;
        emit Cre8ed(tokenId);
    }

    /// @notice exit a CRE8OR from the warehouse
    /// @param tokenId token to exit from the warehouse
    function leaveWarehouse(uint256 tokenId) internal {
        _beforeLeaveWarehouse(tokenId);
        uint256 start = cre8ingStarted[tokenId];
        cre8ingTotal[tokenId] += block.timestamp - start;
        cre8ingStarted[tokenId] = 0;
        emit Uncre8ed(tokenId);
        _afterLeaveWarehouse(tokenId);
    }

    /// @dev validation hook that fires before an exit from cre8ing
    function _beforeLeaveWarehouse(uint256 tokenId) internal virtual {
        IBeforeLeaveWarehouseHook beforeLeaveWarehouseHook = IBeforeLeaveWarehouseHook(hooks[HookType.BeforeLeaveWarehouse]);
        if (
            address(beforeLeaveWarehouseHook) != address(0) &&
            beforeLeaveWarehouseHook.useBeforeLeaveWarehouseHook(tokenId)
        ) {
            beforeLeaveWarehouseHook.beforeLeaveWarehouseOverrideHook(tokenId);
        }
    }

    /// @dev validation hook that fires after an exit from cre8ing
     function _afterLeaveWarehouse(uint256 tokenId) internal virtual {
        IAfterLeaveWarehouseHook afterLeaveWarehouseHook = IAfterLeaveWarehouseHook(hooks[HookType.AfterLeaveWarehouse]);
        if (
            address(afterLeaveWarehouseHook) != address(0) &&
            afterLeaveWarehouseHook.useAfterLeaveWarehouseHook(tokenId)
        ) {
            afterLeaveWarehouseHook.afterLeaveWarehouseOverrideHook(tokenId);
        }
    }


    /**
        * @notice Returns the contract address for a specified hook type.
        * @param hookType The type of hook to retrieve, as defined in the HookType enum.
        * @return The address of the contract implementing the hook interface.
    */
    function getHook(HookType hookType) external view returns (address) {
        return hooks[hookType];
    }


    /**
        * @notice Sets the contract address for a specified hook type.
        * @param hookType The type of hook to set, as defined in the HookType enum.
        * @param hookAddress The address of the contract implementing the hook interface.
    */
    function setHook(HookType hookType, address hookAddress) external virtual onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
        hooks[hookType] = hookAddress;
        emit UpdatedHook(msg.sender, hookType, hookAddress);
    }

}
