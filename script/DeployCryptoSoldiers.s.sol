// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {CryptoSoldiers} from "../src/CryptoSoldiers.sol";

contract DeployCryptoSoldiersScript is Script {
  uint16 private constant TOTAL_SUPPLY = 200;
  CryptoSoldiers cryptoSoldiers;
  address private _owner;

  constructor(address owner_) {
    _owner = owner_;
  }

  function run() public returns (CryptoSoldiers) {
    vm.startBroadcast();
    cryptoSoldiers = new CryptoSoldiers(_owner, "CryptoSoldiers", "CS", TOTAL_SUPPLY);
    vm.stopBroadcast();
    return cryptoSoldiers;
  }
}
