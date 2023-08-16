// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICre8ingV2 {
    /// @dev Emitted when a CRE8OR begins cre8ing.
    event Cre8ed(address, uint256 indexed tokenId);

    // ERC-5192 (recommended for gas efficiency)
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    /// @dev Emitted when a CRE8OR stops cre8ing; either through standard means or
    ///     by expulsion.
    event Uncre8ed(address, uint256 indexed tokenId);

    /// @dev Emitted when a CRE8OR is expelled from the Warehouse.
    event Expelled(address, uint256 indexed tokenId);

    /// @notice Missing cre8ing status
    error CRE8ING_NotCre8ing(address, uint256 tokenId);

    /// @notice Cre8ing Closed
    error Cre8ing_Cre8ingClosed();

    /// @notice Cre8ing
    error Cre8ing_Cre8ing();

    /// @notice Missing Lockup
    error Cre8ing_MissingLockup();

    /// @notice Cre8ing period
    function cre8ingPeriod(
        address,
        uint256
    ) external view returns (bool cre8ing, uint256 current, uint256 total);

    /// @notice open / close staking
    function setCre8ingOpen(address, bool) external;

    /// @notice force removal from staking
    function expelFromWarehouse(address, uint256) external;

    /// @notice function getCre8ingStarted(
    function getCre8ingStarted(
        address _target,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice array of staked tokenIDs
    /// @dev used in cre8ors ui to quickly get list of staked NFTs.
    function cre8ingTokens(
        address _target
    ) external view returns (uint256[] memory stakedTokens);
}
