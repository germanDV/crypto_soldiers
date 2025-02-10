// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// DOCS: https://book.getfoundry.sh/forge/writing-tests

import {Test} from "forge-std/Test.sol";
import {CryptoSoldiers, IERC721} from "../src/CryptoSoldiers.sol";
import {Errors} from "../src/Errors.sol";

contract CryptoSoldiersTest is Test, Errors {
  CryptoSoldiers cryptoSoldiers;

  function setUp() public {
    cryptoSoldiers = new CryptoSoldiers("CryptoSoldiers", "CS");
  }

  function test_name() public view {
    assertEq(cryptoSoldiers.name(), "CryptoSoldiers");
  }

  function test_symbol() public view {
    assertEq(cryptoSoldiers.symbol(), "CS");
  }

  function testRevert_ownerOfInexistentToken() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 0));
    cryptoSoldiers.ownerOf(0);
  }

  function test_mint() public {
    cryptoSoldiers.mint(msg.sender, 42);
    assertEq(cryptoSoldiers.ownerOf(42), msg.sender);
    assertEq(cryptoSoldiers.balanceOf(msg.sender), 1);
  }

  function test_mintEmitsEvent() public {
    // Check the first 3 indexed arguments of the emitted event;
    // do not check the 'data' of the event (unindexed arguments);
    vm.expectEmit(true, true, true, false);

    // Expected event.
    emit IERC721.Transfer(address(0), msg.sender, 999);

    // Call the method that emits the actual event.
    cryptoSoldiers.mint(msg.sender, 999);
  }

  function testRevert_mintAlreadyOwnedToken() public {
    cryptoSoldiers.mint(msg.sender, 77);
    vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyOwnedToken.selector, 77));
    cryptoSoldiers.mint(msg.sender, 77);
  }

  function testRevert_mintNotByContractOwner() public {
    vm.expectRevert("Unauthorized");
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.mint(msg.sender, 42);
  }

  function test_burn() public {
    cryptoSoldiers.mint(msg.sender, 369);
    assertEq(cryptoSoldiers.ownerOf(369), msg.sender);
    assertEq(cryptoSoldiers.balanceOf(msg.sender), 1);

    cryptoSoldiers.burn(369);
    assertEq(cryptoSoldiers.balanceOf(msg.sender), 0);

    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 369));
    cryptoSoldiers.ownerOf(369);
  }
}
