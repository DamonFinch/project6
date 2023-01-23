// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {Cre8ors} from "../src/Cre8ors.sol";
import {TraitRenderer} from "../src/TraitRenderer.sol";
import {DummyMetadataRenderer} from "./utils/DummyMetadataRenderer.sol";
import {IERC721Drop} from "../src/interfaces/IERC721Drop.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TraitRendererTest is Test {
    TraitRenderer public traitRenderer;
    Cre8ors public cre8orsNFTBase;
    DummyMetadataRenderer public dummyRenderer = new DummyMetadataRenderer();

    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
    address public constant DEFAULT_CRE8OR_ADDRESS = address(456);
    address public constant DEFAULT_TRANSFER_ADDRESS = address(0x2);

    function setUp() public {
        traitRenderer = new TraitRenderer(100);
    }

    modifier setupCre8orsNFTBase() {
        cre8orsNFTBase = new Cre8ors({
            _contractName: "CRE8ORS",
            _contractSymbol: "CRE8",
            _initialOwner: DEFAULT_OWNER_ADDRESS,
            _fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
            _editionSize: 10_000,
            _royaltyBPS: 808,
            _metadataRenderer: dummyRenderer,
            _metadataURIBase: "",
            _metadataContractURI: "",
            _salesConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: uint64(block.timestamp + 1000),
                presaleStart: 0,
                presaleEnd: 0,
                publicSalePrice: 0,
                maxSalePurchasePerAddress: 0,
                presaleMerkleRoot: bytes32(0)
            })
        });

        _;
    }

    function test_numberOfTraits() public {
        uint256 traitCount = traitRenderer.numberOfTraits();
        assertEq(traitCount, 0);
    }

    function test_trait(uint256 _traitId, uint256 _tokenId) public {
        if (_traitId >= traitRenderer.numberOfTraits()) {
            vm.expectRevert(
                abi.encodeWithSignature("Trait_NonExisting(uint256)", _traitId)
            );
        }
        string memory trait = traitRenderer.trait(_traitId, _tokenId);
        assertEq(trait, "");
    }

    function test_tokenTraits(uint256 _tokenId) public {
        string[] memory traits = traitRenderer.tokenTraits(_tokenId);
        assertEq(traits.length, traitRenderer.MAX_TRAITS());
    }

    // function test_setTrait(uint256 _traitId, string[] memory _traitUri) public {
    //     vm.expectRevert(
    //         abi.encodeWithSignature("Trait_NonExisting(uint256)", _traitId)
    //     );
    //     string memory trait = traitRenderer.trait(_traitId, 0);
    //     assertEq(trait, "");
    //     emit log_uint(_traitId);

    //     traitRenderer.setTrait(_traitId, _traitUri);
    //     if (_traitUri.length > 0) {
    //         emit log_string("hello");
    //         trait = traitRenderer.trait(_traitId, 0);
    //         assertEq(trait, _traitUri[0]);
    //     }
    // }
}
