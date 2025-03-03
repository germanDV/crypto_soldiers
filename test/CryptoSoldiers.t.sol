// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {CryptoSoldiers, IERC721} from "../src/CryptoSoldiers.sol";
import {Errors} from "../src/Errors.sol";
import {DeployCryptoSoldiersScript} from "../script/DeployCryptoSoldiers.s.sol";

contract CryptoSoldiersTest is Test, Errors {
  CryptoSoldiers cryptoSoldiers;

  function setUp() public {
    DeployCryptoSoldiersScript deployer = new DeployCryptoSoldiersScript(address(this));
    cryptoSoldiers = deployer.run();
  }

  function test_name() public view {
    assertEq(cryptoSoldiers.name(), "CryptoSoldiers");
  }

  function test_symbol() public view {
    assertEq(cryptoSoldiers.symbol(), "CS");
  }

  function test_totalSupply() public view {
    assertEq(cryptoSoldiers.totalSupply(), 200);
  }

  function test_allTokensAssignedToContract() public view {
    assertEq(cryptoSoldiers.balanceOf(address(this)), cryptoSoldiers.totalSupply());
    assertEq(cryptoSoldiers.ownerOf(1), address(this));
    assertEq(cryptoSoldiers.ownerOf(10), address(this));
  }

  function testRevert_ownerOfInexistentToken() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 0));
    cryptoSoldiers.ownerOf(0);
  }

  function test_burn() public {
    address lastOwner = cryptoSoldiers.ownerOf(3);

    // Check the first 3 indexed arguments of the emitted event and the optional 'data'.
    vm.expectEmit(true, true, true, true);

    // Expected event.
    emit IERC721.Transfer(lastOwner, address(0), 3);

    // Call the method that emits the actual event.
    cryptoSoldiers.burn(3);

    // In addition to the event, test state after calling burn.
    assertEq(
      cryptoSoldiers.balanceOf(cryptoSoldiers.contractOwner()),
      cryptoSoldiers.totalSupply() - 1
    );
  }

  function testRevert_ownerOfBurntToken() public {
    cryptoSoldiers.burn(6);
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 6));
    cryptoSoldiers.ownerOf(6);
  }

  function testRevert_doubleBurn() public {
    cryptoSoldiers.burn(9);
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 9));
    cryptoSoldiers.burn(9);
  }

  function test_tokenURI() public view {
    assertEq(cryptoSoldiers.tokenURI(4), "https://api.cryptosoldiers.com/nft/4");
  }

  function testRevert_tokenURIOfInexistentToken() public {
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 450));
    cryptoSoldiers.tokenURI(450);
  }

  function testRevert_tokenURIOfBurntToken() public {
    cryptoSoldiers.burn(3);
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 3));
    cryptoSoldiers.tokenURI(3);
  }

  function test_changeBaseURI() public {
    assertEq(cryptoSoldiers.tokenURI(4), "https://api.cryptosoldiers.com/nft/4");
    cryptoSoldiers.changeBaseURI("https://new.domain/nft/");
    assertEq(cryptoSoldiers.tokenURI(4), "https://new.domain/nft/4");
  }

  function testRevert_changeBaseURINotByContractOwner() public {
    vm.expectRevert(Errors.NotContractOwner.selector);
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.changeBaseURI("https://new.domain/nft/");
  }

  function test_receive() public {
    uint256 balanceBefore = address(cryptoSoldiers).balance;
    (bool sent, ) = address(cryptoSoldiers).call{value: 2 ether}("");
    assertTrue(sent);
    uint256 balanceAfter = address(cryptoSoldiers).balance;
    assertEq(balanceAfter - balanceBefore, 2e18);
  }

  function test_withdraw() public {
    (bool sent, ) = address(cryptoSoldiers).call{value: 400 ether}("");
    assertTrue(sent);
    uint256 balanceBefore = address(cryptoSoldiers).balance;

    address beneficiary = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    cryptoSoldiers.withdraw(beneficiary);

    uint256 balanceAfter = address(cryptoSoldiers).balance;
    assertEq(balanceBefore - balanceAfter, 400e18);
    assertEq(beneficiary.balance, 400e18);
  }

  function test_withdrawZeroBalance() public {
    uint256 balanceBefore = address(cryptoSoldiers).balance;
    address beneficiary = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    cryptoSoldiers.withdraw(beneficiary);
    uint256 balanceAfter = address(cryptoSoldiers).balance;
    assertEq(balanceBefore, balanceAfter);
  }

  function testRevert_withdrawNotByContractOwner() public {
    vm.expectRevert(Errors.NotContractOwner.selector);
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.withdraw(address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA));
  }

  function test_withdrawalEvent() public {
    address beneficiary = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    (bool sent, ) = address(cryptoSoldiers).call{value: 42 ether}("");
    assertTrue(sent);

    vm.expectEmit(true, true, true, true);
    emit IERC721.Withdrawal(beneficiary, 42e18);
    cryptoSoldiers.withdraw(beneficiary);
  }

  function test_buyToken() public {
    address oldOwner = cryptoSoldiers.ownerOf(7);

    address buyer = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    vm.prank(buyer);
    cryptoSoldiers.buyToken(7);

    address newOwner = cryptoSoldiers.ownerOf(7);
    assertNotEq(oldOwner, newOwner);
    assertEq(newOwner, buyer);
  }

  function testRevert_buyTokenWithContractPaused() public {
    cryptoSoldiers.pause();
    vm.expectRevert(Errors.ContractIsPaused.selector);
    address buyer = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    vm.prank(buyer);
    cryptoSoldiers.buyToken(7);
  }

  function test_buyTokenAfterUnpausingContract() public {
    cryptoSoldiers.pause();
    address buyer = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    cryptoSoldiers.unpause();
    vm.prank(buyer);
    cryptoSoldiers.buyToken(27);
    address owner = cryptoSoldiers.ownerOf(27);
    assertEq(owner, buyer);
  }

  function test_EmitContractPaused() public {
    vm.expectEmit(true, true, true, true);
    emit CryptoSoldiers.ContractPaused();
    cryptoSoldiers.pause();
  }

  function test_EmitContractUnpaused() public {
    cryptoSoldiers.pause();
    vm.expectEmit(true, true, true, true);
    emit CryptoSoldiers.ContractUnpaused();
    cryptoSoldiers.unpause();
  }

  function testRevert_pauseNotByOwner() public {
    vm.expectRevert(Errors.NotContractOwner.selector);
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.pause();
  }

  function testRevert_unpauseNotByOwner() public {
    vm.expectRevert(Errors.NotContractOwner.selector);
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.unpause();
  }

  function test_idempotentPause() public {
    cryptoSoldiers.pause();
    cryptoSoldiers.pause();
    assertEq(cryptoSoldiers.isPaused(), true);
  }

  function test_idempotentUnpause() public {
    cryptoSoldiers.pause();
    cryptoSoldiers.unpause();
    cryptoSoldiers.unpause();
    assertEq(cryptoSoldiers.isPaused(), false);
  }

  function test_transferFrom() public {
    address oldOwner = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address newOwner = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);

    vm.prank(oldOwner);
    cryptoSoldiers.buyToken(10);
    assertEq(cryptoSoldiers.ownerOf(10), oldOwner);

    vm.prank(oldOwner);
    cryptoSoldiers.transferFrom(oldOwner, newOwner, 10);
    assertEq(cryptoSoldiers.ownerOf(10), newOwner);
  }

  function testRevert_transferFromNotTokenOwner() public {
    address from = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address to = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    vm.expectRevert(
      abi.encodeWithSelector(Errors.IncorrectOwner.selector, from, 87, address(this))
    );
    vm.prank(from);
    cryptoSoldiers.transferFrom(from, to, 87);
  }

  function testRevert_transferFromInvalidSender() public {
    address from = address(0);
    address to = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSender.selector, from));
    cryptoSoldiers.transferFrom(from, to, 87);
  }

  function testRevert_transferFromInvalidReceiver() public {
    address from = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    address to = address(0);
    vm.expectRevert(abi.encodeWithSelector(Errors.InvalidReceiver.selector, to));
    cryptoSoldiers.transferFrom(from, to, 87);
  }

  function testRevert_transferFromInexistentToken() public {
    address from = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address to = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentToken.selector, 878));
    vm.prank(from);
    cryptoSoldiers.transferFrom(from, to, 878);
  }

  function test_safeTransferFromWithoutData() public {
    address from = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address to = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);

    vm.prank(from);
    cryptoSoldiers.buyToken(9);
    assertEq(cryptoSoldiers.ownerOf(9), from);
    assertEq(cryptoSoldiers.balanceOf(from), 1);
    assertEq(cryptoSoldiers.balanceOf(to), 0);
    assertEq(cryptoSoldiers.ownerOf(9), from);

    vm.prank(from);
    cryptoSoldiers.safeTransferFrom(from, to, 9);
    assertEq(cryptoSoldiers.ownerOf(9), to);
    assertEq(cryptoSoldiers.balanceOf(from), 0);
    assertEq(cryptoSoldiers.balanceOf(to), 1);
    assertEq(cryptoSoldiers.ownerOf(9), to);
  }

  function test_safeTransferFromWithData() public {
    address from = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address to = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);

    vm.prank(from);
    cryptoSoldiers.buyToken(9);
    assertEq(cryptoSoldiers.ownerOf(9), from);
    assertEq(cryptoSoldiers.balanceOf(from), 1);
    assertEq(cryptoSoldiers.balanceOf(to), 0);
    assertEq(cryptoSoldiers.ownerOf(9), from);

    vm.prank(from);
    cryptoSoldiers.safeTransferFrom(from, to, 9, "foo");
    assertEq(cryptoSoldiers.ownerOf(9), to);
    assertEq(cryptoSoldiers.balanceOf(from), 0);
    assertEq(cryptoSoldiers.balanceOf(to), 1);
    assertEq(cryptoSoldiers.ownerOf(9), to);
  }
}
