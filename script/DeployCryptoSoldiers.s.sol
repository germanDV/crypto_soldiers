// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {CryptoSoldiers} from "../src/CryptoSoldiers.sol";

contract DeployCryptoSoldiersScript is Script {
  uint16 private constant TOTAL_SUPPLY = 200;
  CryptoSoldiers cryptoSoldiers;

  // TODO: probably better to move `owner` to a state variable and assing it in the constructor.
  function run(address owner) public returns (CryptoSoldiers) {
    vm.startBroadcast();
    cryptoSoldiers = new CryptoSoldiers(owner, "CryptoSoldiers", "CS", TOTAL_SUPPLY);
    vm.stopBroadcast();
    return cryptoSoldiers;
  }
}
