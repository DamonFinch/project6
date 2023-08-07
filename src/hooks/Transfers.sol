// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {HookBase} from "../hooks/HookBase.sol";
import {IAfterTokenTransfersHook} from "ERC721H/interfaces/IAfterTokenTransfersHook.sol";
import {IBeforeTokenTransfersHook} from "ERC721H/interfaces/IBeforeTokenTransfersHook.sol";
import {Cre8orsERC6551} from "./utils/Cre8orsERC6551.sol";
import {ICre8ors} from "./interfaces/ICre8ors.sol";
import {ICre8ing} from "./interfaces/ICre8ing.sol";
import {IERC721Drop} from "./interfaces/IERC721Drop.sol";
import {ISubscription} from "./subscription/interfaces/ISubscription.sol";

contract TransferHook is
    IAfterTokenTransfersHook,
    IBeforeTokenTransfersHook,
    Cre8orsERC6551
{
    /// @notice Represents the duration of one year in seconds.
    uint64 public constant ONE_YEAR_DURATION = 365 days;

    /// @notice To toggle free subscription in future
    bool public isFreeSubscriptionEnabled = true;

    ///@notice The address of the collection contract that mints and manages the tokens.
    address public cre8orsNFT;

    address public cre8ing;

    /// @dev MUST only be modified by safeTransferWhileCre8ing(); if set to 2 then
    /// the _beforeTokenTransfer() block while cre8ing is disabled.
    uint256 cre8ingTransfer;

    /// @notice mapping of ERC721 to bool whether to use afterTokenTransferHook
    mapping(address => bool) public afterTokenTransfersHookEnabled;
    /// @notice mapping of ERC721 to bool whether to use beforeTokenTransferHook
    mapping(address => bool) public beforeTokenTransfersHookEnabled;

    /// @notice Initializes the contract with the address of the Cre8orsNFT contract.
    /// @param _cre8orsNFT The address of the Cre8orsNFT contract to be used.
    constructor(address _cre8orsNFT) {
        cre8orsNFT = _cre8orsNFT;
    }

    /// @notice Toggle the status of the free subscription feature.
    /// @dev This function can only be called by an admin, identified by the
    ///     "cre8orsNFT" contract address.
    function toggleIsFreeSubscriptionEnabled() public onlyAdmin(cre8orsNFT) {
        isFreeSubscriptionEnabled = !isFreeSubscriptionEnabled;
    }

    /// @notice Set the Cre8orsNFT contract address.
    /// @dev This function can only be called by an admin, identified by the
    ///     "cre8orsNFT" contract address.
    /// @param _cre8orsNFT The new address of the Cre8orsNFT contract to be set.
    function setCre8orsNFT(address _cre8orsNFT) public onlyAdmin(cre8orsNFT) {
        cre8orsNFT = _cre8orsNFT;
    }

    /// @notice Set ERC6551 registry
    /// @param _target target ERC721 contract
    /// @param _registry ERC6551 registry
    function setErc6551Registry(
        address _target,
        address _registry
    ) public onlyAdmin(_target) {
        erc6551Registry[_target] = _registry;
    }

    /// @notice Set ERC6551 account implementation
    /// @param _target target ERC721 contract
    /// @param _implementation ERC6551 account implementation
    function setErc6551Implementation(
        address _target,
        address _implementation
    ) public onlyAdmin(_target) {
        erc6551AccountImplementation[_target] = _implementation;
    }

    /// @notice Toggle afterTokenTransfers hook.
    /// add admin only
    /// @param _target target ERC721 contract
    /// @param _enabled enable afterTokenTransferHook
    function setAfterTokenTransfersEnabled(
        address _target,
        bool _enabled
    ) public onlyAdmin(_target) {
        afterTokenTransfersHookEnabled[_target] = _enabled;
    }

    /// @notice Custom implementation for AfterTokenTransfers Hook.
    function afterTokenTransfersHook(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) external {
        if (from != address(0)) {
            return;
        }

        // msg.sender is the ERC721 contract e.g. Cre8ors
        address _cre8orsNFT = msg.sender;

        if (erc6551Registry[_cre8orsNFT] != address(0)) {
            createTokenBoundAccounts(_cre8orsNFT, startTokenId, quantity);
        }

        // Subscription logic
        uint256[] memory tokenIds = getTokenIds(startTokenId, quantity);

        ISubscription(subscription).updateSubscriptionForFree({
            target: _cre8orsNFT,
            duration: ONE_YEAR_DURATION,
            tokenIds: tokenIds
        });
    }

    // /// @notice Custom implementation for BeforeTokenTransfers Hook.
    function beforeTokenTransfersHook(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external {
        emit BeforeTokenTransfersHookUsed(from, to, startTokenId, quantity);
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (
                ICre8ing(cre8ing).getCre8ingStarted(msg.sender, tokenId) != 0 &&
                cre8ingTransfer != 1
            ) {
                revert ICre8ing.Cre8ing_Cre8ing();
            }
        }
    }

    /// @notice Transfer a token between addresses while the CRE8OR is cre8ing,
    ///  thus not resetting the cre8ing period.
    function safeTransferWhileCre8ing(
        address from,
        address to,
        uint256 tokenId
    ) external {
        address _cre8orsNFT = cre8orsNFT;
        if (ICre8ors(_cre8orsNFT).ownerOf(tokenId) != msg.sender) {
            revert IERC721Drop.Access_OnlyOwner();
        }
        cre8ingTransfer = 1;
        ICre8ors(_cre8orsNFT).safeTransferFrom(from, to, tokenId);
        cre8ingTransfer = 0;
    }

    function setCre8ing(
        address _cre8ing
    ) external virtual onlyAdmin(cre8orsNFT) {
        cre8ing = _cre8ing;
    }

    /// @notice Only allow for users with admin access
    /// @param _target target ERC721 contract
    modifier onlyAdmin(address _target) {
        if (!isAdmin(_target, msg.sender)) {
            revert IERC721Drop.Access_OnlyAdmin();
        }

        _;
    }

    /// @notice Getter for admin role associated with the contract to handle minting
    /// @param _target target ERC721 contract
    /// @param user user address
    /// @return boolean if address is admin
    function isAdmin(address _target, address user) public view returns (bool) {
        return IERC721Drop(_target).isAdmin(user);
    }

    /// @notice Get an array of token IDs starting from a given token ID and up
    ///     to a specified quantity.
    /// @param startTokenId The starting token ID.
    /// @param quantity The number of token IDs to generate.
    /// @return tokenIds An array containing the generated token IDs.
    function getTokenIds(
        uint256 startTokenId,
        uint256 quantity
    ) public pure returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; ) {
            tokenIds[i] = startTokenId + i;

            unchecked {
                ++i;
            }
        }
    }
}
