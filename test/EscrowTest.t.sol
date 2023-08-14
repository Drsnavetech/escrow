// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Escrow} from "../src/Escrow.sol";
import {RealEstate} from "../src/RealEstate.sol";
import {DeployEscrow} from "../script/DeployScript.s.sol";

contract EscrowTest is Test {
    Escrow escrow;
    RealEstate realEstate;
    address public SELLER = makeAddr("seller");
    address public BUYER = makeAddr("buyer");
    address public RANDOM = makeAddr("random");
    uint256 public constant STARTING_BALANCE = 20 ether;
    uint256 public constant ESCROW_AMOUNT = 5 ether;
    uint256 public constant PURCHASE_PRICE = 15 ether;

    function setUp() external {
        DeployEscrow deployer = new DeployEscrow();
        (escrow, realEstate) = deployer.run();

        vm.deal(SELLER, STARTING_BALANCE);
    }

    function testMintingWork() public {
        vm.prank(SELLER);
        realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );
        assert(realEstate.totalSupply() == uint256(1));
    }

    function testGetnftAddressIsRealEstateAddress() public view {
        address nftAddress = escrow.getNftAddress();
        address realEstateAddress = address(realEstate);

        assert(realEstateAddress == nftAddress);
    }

    function testSellerIsMsgSender() public {
        assertEq(escrow.getSeller(), msg.sender);
    }

    // function testEscrowAddressHasBeenApproved() public {
    //     vm.startPrank(escrow.getSeller());
    //     uint256 tokenId = realEstate.mintNft(
    //         "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
    //     );

    //     // realEstate.approve(address(escrow), tokenId);
    //     escrow.approveTransfer(tokenId);
    // }

    function testNFThasBeenlistedInEscrow() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);

        assert(realEstate.ownerOf(tokenId) == address(escrow));
    }

    modifier listNft() {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        _;
    }

    function testGetbuyer() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        assert(escrow.getbuyer(tokenId) == address(BUYER));
    }

    function testisListed() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        assert(escrow.getIslisted(tokenId) == true);
    }

    function testRevertsIfDepositlessthanEscrowAmount() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        vm.expectRevert();
        vm.prank(BUYER);
        escrow.depositEarnest{value: STARTING_BALANCE}(tokenId);
    }

    function testRevertsIfNotBuyerDepositing() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        vm.expectRevert();
        vm.prank(SELLER);
        escrow.depositEarnest{value: STARTING_BALANCE}(tokenId);
    }

    function testDepositEarnestMoney() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        hoax(BUYER, STARTING_BALANCE);
        escrow.depositEarnest{value: ESCROW_AMOUNT}(tokenId);

        assert(escrow.getBalance() == ESCROW_AMOUNT);
    }

    function testDepositbalanceMoney() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        hoax(BUYER, STARTING_BALANCE);
        escrow.depositBalance{value: PURCHASE_PRICE}(tokenId);

        assert(escrow.getBalance() == PURCHASE_PRICE);
    }

    function testisApprovedbyBuyer() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        hoax(BUYER, STARTING_BALANCE);
        escrow.approveSale(tokenId);

        assert(escrow.getIsApproved(tokenId, BUYER) == true);
    }

    function testisApprovedbyseller() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        escrow.approveSale(tokenId);

        assert(escrow.getIsApproved(tokenId, escrow.getSeller()) == true);
    }

    function testfinalizeSale() public {
        vm.startPrank(escrow.getSeller());
        uint256 tokenId = realEstate.mintNft(
            "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json"
        );

        realEstate.approve(address(escrow), tokenId);
        escrow.list(tokenId, BUYER, ESCROW_AMOUNT, PURCHASE_PRICE);
        escrow.approveSale(tokenId);
        hoax(BUYER, STARTING_BALANCE);
        escrow.approveSale(tokenId);
        hoax(BUYER, STARTING_BALANCE);
        escrow.depositBalance{value: PURCHASE_PRICE + ESCROW_AMOUNT}(tokenId);
        escrow.finalizeSale(tokenId);
        assert(escrow.getBalance() == 0);
        assert(realEstate.ownerOf(tokenId) == BUYER);
    }
}
