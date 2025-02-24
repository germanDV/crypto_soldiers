// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {CryptoSoldiers} from "../src/CryptoSoldiers.sol";

contract DeployCryptoSoldiersScript is Script {
  CryptoSoldiers cryptoSoldiers;

  uint16 private constant TOTAL_SUPPLY = 200;

  function setUp() public {}

  function run() public returns (CryptoSoldiers) {
    vm.startBroadcast();
    cryptoSoldiers = new CryptoSoldiers("CryptoSoldiers", "CS", TOTAL_SUPPLY);
    vm.stopBroadcast();
    return cryptoSoldiers;
  }
}
