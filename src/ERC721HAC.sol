// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721HAC} from "./interfaces/IERC721HAC.sol";
import {ERC721AC} from "ERC721C/erc721c/ERC721AC.sol";

/**
 * @title ERC721HAC
 * @author Cre8ors Inc.
 * @notice Extends Limit Break's ERC721-AC implementation with Hook functionality, which
 *         allows the contract owner to override hooks associated with core ERC721 functions.
 */
contract ERC721HAC is IERC721HAC, ERC721AC {
    constructor(
        string memory _contractName,
        string memory _contractSymbol
    ) ERC721AC(_contractName, _contractSymbol) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////
    /// ERC721 overrides
    /////////////////////////////////////////////////
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        if (_useBalanceOfHook(owner)) {
            return _balanceOfHook(owner);
        }
        return super.balanceOf(owner);
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        if (_useOwnerOfHook(tokenId)) {
            return _ownerOfHook(tokenId);
        }
        return super.ownerOf(tokenId);
    }

    function approve(
        address approved,
        uint256 tokenId
    ) public payable virtual override {
        if (_useApproveHook(approved, tokenId)) {
            _approveHook(approved, tokenId);
        } else {
            super.approve(approved, tokenId);
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (_useSetApprovalForAllHook(msg.sender, operator, approved)) {
            _setApprovalForAllHook(msg.sender, operator, approved);
        } else {
            super.setApprovalForAll(operator, approved);
        }
    }

    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        if (_useGetApprovedHook(tokenId)) {
            return _getApprovedHook(tokenId);
        }
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        if (_useIsApprovedForAllHook(owner, operator)) {
            return _isApprovedForAllHook(owner, operator);
        }
        return super.isApprovedForAll(owner, operator);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        if (_useTransferFromHook(from, to, tokenId)) {
            _transferFromHook(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual override {
        if (_useSafeTransferFromHook(msg.sender, from, to, tokenId, data)) {
            _safeTransferFromHook(msg.sender, from, to, tokenId, data);
        } else {
            super.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        if (_useSafeTransferFromHook(msg.sender, from, to, tokenId, "")) {
            _safeTransferFromHook(msg.sender, from, to, tokenId, "");
        } else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    /////////////////////////////////////////////////
    /// ERC721 Hooks
    /////////////////////////////////////////////////

    /// @dev balanceOf - ERC721
    function _balanceOfHook(address) internal view virtual returns (uint256) {}

    function _useBalanceOfHook(address) internal view virtual returns (bool) {}

    /// @dev ownerOf - ERC721
    function _ownerOfHook(uint256) internal view virtual returns (address) {}

    function _useOwnerOfHook(uint256) internal view virtual returns (bool) {}

    /// @dev approve - ERC721
    function _approveHook(address approved, uint256 tokenId) internal virtual {}

    function _useApproveHook(
        address,
        uint256
    ) internal view virtual returns (bool) {}

    /// @dev setApprovalForAll - ERC721
    function _setApprovalForAllHook(
        address owner,
        address operator,
        bool approved
    ) internal virtual {}

    function _useSetApprovalForAllHook(
        address owner,
        address operator,
        bool approved
    ) internal view virtual returns (bool) {}

    /// @dev getApproved - ERC721
    function _getApprovedHook(
        uint256 tokenId
    ) internal view virtual returns (address) {}

    function _useGetApprovedHook(
        uint256 tokenId
    ) internal view virtual returns (bool) {}

    /// @dev isApprovedForAll - ERC721
    function _isApprovedForAllHook(
        address owner,
        address operator
    ) internal view virtual returns (bool) {}

    function _useIsApprovedForAllHook(
        address owner,
        address operator
    ) internal view virtual returns (bool) {}

    /// @dev transferFrom - ERC721
    function _transferFromHook(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _useTransferFromHook(
        address from,
        address to,
        uint256 tokenId
    ) internal view virtual returns (bool) {}

    /// @dev safeTransferFrom - ERC721
    function _safeTransferFromHook(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    function _useSafeTransferFromHook(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal view virtual returns (bool) {}

    /////////////////////////////////////////////////
    /// ERC721C Override
    /////////////////////////////////////////////////
    function _requireCallerIsContractOwner() internal view virtual override {}
}