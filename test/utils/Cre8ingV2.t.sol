// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {Cre8ingV2} from "../../src/utils/Cre8ingV2.sol";
import {ICre8ingV2} from "../../src/interfaces/ICre8ingV2.sol";
import {ILockup} from "../../src/interfaces/ILockup.sol";
import {Lockup} from "../../src/utils/Lockup.sol";
import {DummyMetadataRenderer} from "./DummyMetadataRenderer.sol";
import {IERC721Drop} from "../../src/interfaces/IERC721Drop.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Cre8orTestBase} from "./Cre8orTestBase.sol";
import {MinterAdminCheck} from "../../src/minter/MinterAdminCheck.sol";
import {TransferHook} from "../../src/hooks/Transfers.sol";
import {IERC721ACH} from "ERC721H/interfaces/IERC721ACH.sol";

contract Cre8ingV2Test is Test, Cre8orTestBase {
    Cre8ingV2 public cre8ingBase;
    address public constant DEFAULT_CRE8OR_ADDRESS = address(456);
    address public constant DEFAULT_TRANSFER_ADDRESS = address(0x2);
    Lockup lockup = new Lockup();

    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    function setUp() public {
        Cre8orTestBase.cre8orSetup();
        cre8ingBase = new Cre8ingV2();
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        transferHook = new TransferHook(
            address(cre8orsNFTBase),
            address(erc6551Registry),
            address(erc6551Implementation)
        );
        transferHook.setCre8ing(address(cre8ingBase));
        cre8orsNFTBase.setHook(
            IERC721ACH.HookType.BeforeTokenTransfers,
            address(transferHook)
        );
        vm.stopPrank();
    }

    function test_cre8ingPeriod(uint256 _tokenId) public {
        _expectUnlocked(_tokenId);
    }

    function test_cre8ingOpen() public {
        assertEq(cre8ingBase.cre8ingOpen(address(cre8orsNFTBase)), false);
    }

    function test_setCre8ingOpenReverts_AdminAccess_MissingRoleOrAdmin(
        bool _isOpen
    ) public {
        assertEq(cre8ingBase.cre8ingOpen(address(cre8orsNFTBase)), false);
        vm.expectRevert(IERC721Drop.Access_OnlyAdmin.selector);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), _isOpen);
        assertEq(cre8ingBase.cre8ingOpen(address(cre8orsNFTBase)), false);
    }

    function test_setCre8ingOpen(bool _isOpen) public {
        assertEq(cre8ingBase.cre8ingOpen(address(cre8orsNFTBase)), false);
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), _isOpen);
        assertEq(cre8ingBase.cre8ingOpen(address(cre8orsNFTBase)), _isOpen);
    }

    function test_toggleCre8ingRevert_OwnerQueryForNonexistentToken(
        uint256 _tokenId
    ) public {
        _expectUnlocked(_tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        vm.expectRevert(
            abi.encodeWithSignature("OwnerQueryForNonexistentToken()")
        );
        cre8ingBase.toggleCre8ingTokens(address(cre8orsNFTBase), tokenIds);
    }

    function test_toggleCre8ingRevert_Cre8ing_Cre8ingClosed() public {
        uint256 _tokenId = 1;
        _expectUnlocked(_tokenId);

        cre8orsNFTBase.purchase(1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        vm.expectRevert(ICre8ingV2.Cre8ing_Cre8ingClosed.selector);
        cre8ingBase.toggleCre8ingTokens(address(cre8orsNFTBase), tokenIds);
    }

    function test_toggleCre8ing_ONE(uint256 _tokenToStake) public {
        _assumeUint256(_tokenToStake);
        _expectUnlocked(_tokenToStake);

        cre8orsNFTBase.purchase(_tokenToStake);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        _toggleCre8ingTokens(_tokenToStake);

        _expectLocked(_tokenToStake);
    }

    function test_toggleCre8ing_Unstake_ONE(uint256 _tokenToStake) public {
        test_toggleCre8ing_ONE(_tokenToStake);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenToStake;

        // VERIFY UNSTAKED
        _toggleCre8ingTokens(tokenIds, false);
    }

    function test_blockCre8ingTransfer() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        vm.startPrank(DEFAULT_CRE8OR_ADDRESS);
        _toggleCre8ingTokens(_tokenId);
        vm.expectRevert(abi.encodeWithSignature("Cre8ing_Cre8ing()"));
        cre8orsNFTBase.safeTransferFrom(
            DEFAULT_CRE8OR_ADDRESS,
            DEFAULT_OWNER_ADDRESS,
            _tokenId
        );
    }

    function test_safeTransferWhileCre8ing() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        vm.startPrank(DEFAULT_CRE8OR_ADDRESS);
        _toggleCre8ingTokens(_tokenId);
        assertEq(cre8orsNFTBase.ownerOf(_tokenId), DEFAULT_CRE8OR_ADDRESS);
        transferHook.safeTransferWhileCre8ing(
            DEFAULT_CRE8OR_ADDRESS,
            DEFAULT_TRANSFER_ADDRESS,
            _tokenId
        );

        assertEq(cre8orsNFTBase.ownerOf(_tokenId), DEFAULT_TRANSFER_ADDRESS);

        _expectLocked(_tokenId);
    }

    function test_safeTransferWhileCre8ingRevert_Access_OnlyOwner() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        _toggleCre8ingTokens(_tokenId);
        assertEq(cre8orsNFTBase.ownerOf(_tokenId), DEFAULT_CRE8OR_ADDRESS);
        vm.startPrank(DEFAULT_TRANSFER_ADDRESS);
        vm.expectRevert(abi.encodeWithSignature("Access_OnlyOwner()"));
        transferHook.safeTransferWhileCre8ing(
            DEFAULT_CRE8OR_ADDRESS,
            DEFAULT_TRANSFER_ADDRESS,
            _tokenId
        );
        assertEq(cre8orsNFTBase.ownerOf(_tokenId), DEFAULT_CRE8OR_ADDRESS);
    }

    function test_expelFromWarehouseRevert_uncre8ed() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        vm.expectRevert(IERC721Drop.Access_OnlyAdmin.selector);
        cre8ingBase.expelFromWarehouse(address(cre8orsNFTBase), _tokenId);
    }

    function test_expelFromWarehouseRevert_AccessControl() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        _toggleCre8ingTokens(_tokenId);
        vm.prank(DEFAULT_OWNER_ADDRESS);

        _expectLocked(_tokenId);

        vm.startPrank(DEFAULT_CRE8OR_ADDRESS);
        vm.expectRevert(IERC721Drop.Access_OnlyAdmin.selector);
        cre8ingBase.expelFromWarehouse(address(cre8orsNFTBase), _tokenId);
        _expectLocked(_tokenId);
    }

    function test_expelFromWarehouse() public {
        uint256 _tokenId = 1;
        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        cre8orsNFTBase.purchase(1);

        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);

        vm.prank(DEFAULT_CRE8OR_ADDRESS);
        _toggleCre8ingTokens(_tokenId);
        vm.startPrank(DEFAULT_OWNER_ADDRESS);

        _expectLocked(_tokenId);

        _expectUnlockedEmit(_tokenId);
        cre8ingBase.expelFromWarehouse(address(cre8orsNFTBase), _tokenId);

        _expectUnlocked(_tokenId);
    }

    function test_cre8ingTokens() public {
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8orsNFTBase.setSaleConfiguration({
            erc20PaymentToken: address(0),
            publicSaleStart: 0,
            publicSaleEnd: type(uint64).max,
            presaleStart: 0,
            presaleEnd: 0,
            publicSalePrice: 0,
            maxSalePurchasePerAddress: 1000,
            presaleMerkleRoot: bytes32(0)
        });
        vm.deal(address(456), 10 ether);
        cre8orsNFTBase.purchase(100);
        uint256[] memory staked = cre8ingBase.cre8ingTokens(
            address(cre8orsNFTBase)
        );
        assertEq(staked.length, 100);
        for (uint256 i = 0; i < staked.length; i++) {
            assertEq(staked[i], 0);
        }
        uint256[] memory unstaked = new uint256[](100);
        for (uint256 i = 0; i < unstaked.length; i++) {
            unstaked[i] = i + 1;
        }
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);
        _toggleCre8ingTokens(unstaked, true);
        staked = cre8ingBase.cre8ingTokens(address(cre8orsNFTBase));
        for (uint256 i = 0; i < staked.length; i++) {
            assertEq(staked[i], i + 1);
        }
        assertEq(staked.length, 100);
    }

    function test_inializeStakingAndLockup(
        uint256 _quantity,
        address _minter
    ) public {
        _assumeUint256(_quantity);

        // open Staking
        open_staking();

        // buy tokens
        cre8orsNFTBase.purchase(_quantity);

        // generate list of tokens
        uint256[] memory tokenIds = generateUnstakedTokenIds(_quantity);

        // function under test - inializeStakingAndLockup
        grant_minter_role(_minter);
        vm.prank(_minter);
        cre8ingBase.inializeStaking(address(cre8orsNFTBase), tokenIds);

        // assertions
        verifyStaked(_quantity, true);
    }

    function test_inializeStakingAndLockup_revert_Cre8ing_Cre8ingClosed(
        uint256 _quantity,
        address _minter
    ) public {
        _assumeUint256(_quantity);

        // buy tokens
        cre8orsNFTBase.purchase(_quantity);

        // generate list of tokens
        uint256[] memory tokenIds = generateUnstakedTokenIds(_quantity);

        // function under test - inializeStakingAndLockup
        grant_minter_role(_minter);
        vm.prank(_minter);
        vm.expectRevert(ICre8ingV2.Cre8ing_Cre8ingClosed.selector);
        cre8ingBase.inializeStaking(address(cre8orsNFTBase), tokenIds);

        // assertions
        verifyStaked(_quantity, false);
    }

    function test_inializeStakingAndLockup_revert_MissingMinterRole(
        uint256 _quantity
    ) public {
        _assumeUint256(_quantity);

        // buy tokens
        cre8orsNFTBase.purchase(_quantity);

        // open Staking
        open_staking();

        // generate list of tokens
        uint256[] memory tokenIds = generateUnstakedTokenIds(_quantity);

        // function under test - inializeStakingAndLockup
        vm.expectRevert(
            MinterAdminCheck.AdminAccess_MissingMinterOrAdmin.selector
        );
        cre8ingBase.inializeStaking(address(cre8orsNFTBase), tokenIds);

        // assertions
        verifyStaked(_quantity, false);
    }

    function test_inializeStaking_MULTIPLE_TIMES_ALL(uint256 _quantity) public {
        _assumeUint256(_quantity);

        // buy tokens
        cre8orsNFTBase.purchase(_quantity);

        // open Staking
        open_staking();

        // generate list of tokens
        uint256[] memory tokenIds = generateUnstakedTokenIds(_quantity);

        // function under test - inializeStakingAndLockup multiple times
        _initializeStaking(tokenIds);
        _initializeStaking(tokenIds);
    }

    function test_inializeStaking_MULTIPLE_TIMES_ONE(
        uint256 _quantity,
        address _minter
    ) public {
        _assumeUint256(_quantity);

        // buy tokens
        vm.assume(_minter != address(0));
        vm.prank(_minter);
        cre8orsNFTBase.purchase(_quantity);

        // open Staking
        open_staking();

        // generate list of tokens
        uint256[] memory tokenIds = generateUnstakedTokenIds(1);

        // stake 1 token
        grant_minter_role(_minter);
        vm.prank(_minter);
        _toggleCre8ingTokens(tokenIds, true);

        // function under test - inializeStakingAndLockup
        _initializeStaking(tokenIds);
    }

    function _toggleCre8ingTokens(uint256 _tokenId) internal {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        _toggleCre8ingTokens(tokenIds, true);
    }

    function _toggleCre8ingTokens(
        uint256[] memory _tokenIds,
        bool _expectIsLocked
    ) internal {
        if (_expectIsLocked) {
            _expectLockedEmit(_tokenIds[0]);
        } else {
            _expectUnlockedEmit(_tokenIds[0]);
        }
        cre8ingBase.toggleCre8ingTokens(address(cre8orsNFTBase), _tokenIds);
    }

    function _initializeStaking(uint256[] memory _tokenIds) internal {
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.inializeStaking(address(cre8orsNFTBase), _tokenIds);

        // assertions
        verifyStaked(_tokenIds.length, true);
    }

    function grant_minter_role(address _minter) internal {
        bytes32 role = cre8orsNFTBase.MINTER_ROLE();
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8orsNFTBase.grantRole(role, _minter);
    }

    function open_staking() internal {
        vm.prank(DEFAULT_OWNER_ADDRESS);
        cre8ingBase.setCre8ingOpen(address(cre8orsNFTBase), true);
    }

    function verifyStaked(uint256 _quantity, bool _lockedAndStaked) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            // Token is Staked
            (bool cre8ing, , ) = cre8ingBase.cre8ingPeriod(
                address(cre8orsNFTBase),
                i + 1
            );
            assertEq(cre8ing, _lockedAndStaked);
        }
    }

    function _expectUnlocked(uint256 _tokenId) internal {
        (bool cre8ing, uint256 current, uint256 total) = cre8ingBase
            .cre8ingPeriod(address(cre8orsNFTBase), _tokenId);
        assertEq(cre8ing, false);
        assertEq(current, 0);
        assertEq(total, 0);
    }

    function _expectLocked(uint256 _tokenId) internal {
        (bool cre8ing, , ) = cre8ingBase.cre8ingPeriod(
            address(cre8orsNFTBase),
            _tokenId
        );
        assertEq(cre8ing, true);
    }

    function _expectLockedEmit(uint256 _tokenId) internal {
        vm.expectEmit(true, true, true, true);
        emit Locked(_tokenId);
    }

    function _expectUnlockedEmit(uint256 _tokenId) internal {
        vm.expectEmit(true, true, true, true);
        emit Unlocked(_tokenId);
    }

    function generateUnstakedTokenIds(
        uint256 _quantity
    ) internal returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            tokenIds[i] = i + 1;
            // Token is Unstaked
            _expectUnlocked(i + 1);
        }
    }
}
