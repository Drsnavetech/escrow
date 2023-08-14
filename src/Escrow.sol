// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;

    function approve(address _approved, uint256 _tokenId) external;
}

contract Escrow {
    address private s_nftAddress;
    address payable private immutable i_seller;
    address private s_inspector;
    address private s_lender;
    mapping(uint256 => bool) private s_isListed;
    mapping(uint256 => uint256) private s_purchasePrice;
    mapping(uint256 => uint256) private s_escrowAmount;
    mapping(uint256 => address) private s_buyer;
    mapping(address => uint256) private s_addressToAmountFunded;
    mapping(uint256 => mapping(address => bool)) private s_isApproved;

    constructor(address _nftAddress) {
        s_nftAddress = _nftAddress;
        i_seller = payable(msg.sender);
        //s_inspector = _inspector;
        //s_lender = _lender;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlySeller() {
        require(msg.sender == i_seller, "Only seller can call this method");
        _;
    }

    modifier onlyBuyer(uint256 nftId) {
        require(msg.sender == s_buyer[nftId], "Buyers Only");
        _;
    }

    // function approveTransfer(uint256 tokenId) public onlySeller {
    //     IERC721(s_nftAddress).approve(address(this), tokenId);
    // }

    function list(
        uint256 _nftId,
        address buyer,
        uint256 escrowAmount,
        uint256 purchasePrice
    ) public onlySeller {
        IERC721(s_nftAddress).transferFrom(msg.sender, address(this), _nftId);
        s_isListed[_nftId] = true;
        s_buyer[_nftId] = buyer;
        s_escrowAmount[_nftId] = escrowAmount;
        s_purchasePrice[_nftId] = purchasePrice;
    }

    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId) {
        require(
            msg.value >= getEscrowAmount(_nftId),
            "Didn't send enough money"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function depositBalance(uint256 _nftId) public payable onlyBuyer(_nftId) {
        require(
            msg.value >= getPurchasePrice(_nftId),
            "Didn't send enough money"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function approveSale(uint256 _nftId) public {
        s_isApproved[_nftId][msg.sender] = true;
    }

    function finalizeSale(uint256 _nftId) public {
        require(s_isApproved[_nftId][s_buyer[_nftId]]);
        require(s_isApproved[_nftId][i_seller]);
        require(
            address(this).balance >=
                (s_purchasePrice[_nftId] + s_escrowAmount[_nftId])
        );

        (bool callSuccess, ) = payable(i_seller).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
        IERC721(s_nftAddress).transferFrom(
            address(this),
            s_buyer[_nftId],
            _nftId
        );

        s_isListed[_nftId] = false;
    }

    function cancelSale(uint256 _nftId) public {
        if (
            getIsApproved(_nftId, getbuyer(_nftId)) == false &&
            getIsApproved(_nftId, getSeller())
        ) {
            payable(s_buyer[_nftId]).transfer(
                s_addressToAmountFunded[s_buyer[_nftId]]
            );
        }
    }

    /* getter functions */
    function getNftAddress() public view returns (address) {
        return s_nftAddress;
    }

    function getSeller() public view returns (address) {
        return i_seller;
    }

    function getPurchasePrice(uint256 nftId) public view returns (uint256) {
        return s_purchasePrice[nftId];
    }

    function getIslisted(uint256 nftId) public view returns (bool) {
        return s_isListed[nftId];
    }

    function getbuyer(uint256 nftId) public view returns (address) {
        return s_buyer[nftId];
    }

    function getIsApproved(
        uint256 nftId,
        address approval
    ) public view returns (bool) {
        return s_isApproved[nftId][approval];
    }

    function getEscrowAmount(uint256 nftId) public view returns (uint256) {
        return s_escrowAmount[nftId];
    }

    function getAmountPaidbyBuyer(
        address buyerAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[buyerAddress];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
