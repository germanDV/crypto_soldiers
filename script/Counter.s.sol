// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CryptoSoldiers} from "../src/CryptoSoldiers.sol";

contract CryptoSoldiersScript is Script {
  CryptoSoldiers cryptoSoldiers;

  function setUp() public {}

  function run() public {
    vm.startBroadcast();
    cryptoSoldiers = new CryptoSoldiers("CryptoSoldiers", "CS");
    vm.stopBroadcast();
  }
}
