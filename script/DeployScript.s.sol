// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";
import {RealEstate} from "../src/RealEstate.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract DeployEscrow is Script {
    function run() external returns (Escrow, RealEstate) {
        vm.startBroadcast();

        RealEstate realestate = new RealEstate();

        Escrow escrow = new Escrow(address(realestate));

        // minting

        for (uint256 i = 1; i < 4; i++) {
            string memory mintUrl = string.concat(
                "https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/",
                Strings.toString(i),
                ".json"
            );
            uint256 tokenId = realestate.mintNft(mintUrl);

            realestate.approve(address(escrow), tokenId);
        }

        vm.stopBroadcast();
        return (escrow, realestate);
    }
}
