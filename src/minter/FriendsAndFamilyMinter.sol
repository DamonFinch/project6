// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721A} from "lib/ERC721A/contracts/interfaces/IERC721A.sol";
import {ICre8ors} from "../interfaces/ICre8ors.sol";
import {IERC721Drop} from "../interfaces/IERC721Drop.sol";
import {ILockup} from "../interfaces/ILockup.sol";
import {IMinterUtilities} from "../interfaces/IMinterUtilities.sol";
import {IFriendsAndFamilyMinter} from "../interfaces/IFriendsAndFamilyMinter.sol";
import {ISubscription} from "../subscription/interfaces/ISubscription.sol";

contract FriendsAndFamilyMinter is IFriendsAndFamilyMinter {
    uint64 public constant ONE_YEAR_DURATION = 365 days;

    ///@notice Mapping to track whether an address has discount for free mint.
    mapping(address => bool) public hasDiscount;

    ///@notice The address of the collection contract that mints and manages the tokens.
    address public cre8orsNFT;
    ///@notice The address of the minter utility contract that contains shared utility info.
    address public minterUtilityContractAddress;

    /// @dev The address of the subscription contract.
    address public subscription;

    ///@notice mapping of address to quantity of free mints claimed.
    mapping(address => uint256) public totalClaimed;

    constructor(address _cre8orsNFT, address _minterUtilityContractAddress, address _subscription) {
        cre8orsNFT = _cre8orsNFT;
        minterUtilityContractAddress = _minterUtilityContractAddress;
        subscription = _subscription;
    }

    /// @dev Mints a new token for the specified recipient and performs additional actions, such as setting the lockup (if applicable).
    /// @param recipient The address of the recipient who will receive the minted token.
    /// @return The token ID of the minted token.
    function mint(
        address recipient
    ) external onlyExistingDiscount(recipient) returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = ICre8ors(cre8orsNFT).adminMint(recipient, 1);

        // Subscribe for 1 year
        ISubscription(subscription).updateSubscriptionForFree({
            target: cre8orsNFT,
            duration: ONE_YEAR_DURATION,
            tokenId: pfpTokenId
        });

        totalClaimed[recipient] += 1;

        // Reset discount for the recipient
        hasDiscount[recipient] = false;

        // Set lockup information (optional)
        ILockup lockup = ICre8ors(cre8orsNFT).cre8ing().lockUp(cre8orsNFT);
        if (address(lockup) != address(0)) {
            IMinterUtilities minterUtility = IMinterUtilities(
                minterUtilityContractAddress
            );
            uint256 lockupDate = block.timestamp + 8 weeks;
            uint256 unlockPrice = minterUtility.calculateUnlockPrice(1, true);
            bytes memory data = abi.encode(lockupDate, unlockPrice);
            lockup.setUnlockInfo(cre8orsNFT, pfpTokenId, data);
        }

        // Return the token ID of the minted token
        return pfpTokenId;
    }

    /// @dev Grants a discount to the specified recipient, allowing them to mint tokens without paying the regular price.
    /// @param recipient The address of the recipient who will receive the discount.
    function addDiscount(address recipient) external onlyAdmin {
        if (hasDiscount[recipient]) {
            revert ExistingDiscount();
        }
        hasDiscount[recipient] = true;
    }

    /// @dev Removes the discount from the specified recipient, preventing them from minting tokens with a discount.
    /// @param recipient The address of the recipient whose discount will be removed.
    function removeDiscount(
        address recipient
    ) external onlyAdmin onlyExistingDiscount(recipient) {
        hasDiscount[recipient] = false;
    }

    /// @dev Sets a new address for the MinterUtilities contract.
    /// @param _newMinterUtilityContractAddress The address of the new MinterUtilities contract.
    function setNewMinterUtilityContractAddress(
        address _newMinterUtilityContractAddress
    ) external onlyAdmin {
        minterUtilityContractAddress = _newMinterUtilityContractAddress;
    }

    function setSubscription(address newSubscription) external onlyAdmin {
        if (newSubscription == address(0)) {
            revert ISubscription.SubscriptionCannotBeZeroAddress();
        }

        subscription = newSubscription;
    }

    /// @dev Modifier that restricts access to only the contract's admin.
    modifier onlyAdmin() {
        if (!ICre8ors(cre8orsNFT).isAdmin(msg.sender)) {
            revert IERC721Drop.Access_OnlyAdmin();
        }
        _;
    }

    /// @dev Modifier that checks if the specified recipient has a discount.
    /// @param recipient The address of the recipient to check for the discount.
    modifier onlyExistingDiscount(address recipient) {
        if (!hasDiscount[recipient]) {
            revert MissingDiscount();
        }
        _;
    }
}
