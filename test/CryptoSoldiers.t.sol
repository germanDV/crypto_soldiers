// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CryptoSoldiers, IERC721} from "../src/CryptoSoldiers.sol";
import {Errors} from "../src/Errors.sol";
import {DeployCryptoSoldiersScript} from "../script/DeployCryptoSoldiers.s.sol";

contract CryptoSoldiersTest is Test, Errors {
  CryptoSoldiers cryptoSoldiers;

  function setUp() public {
    DeployCryptoSoldiersScript deployer = new DeployCryptoSoldiersScript();
    cryptoSoldiers = deployer.run();

    // Make CryptoSoldiersTest the owner of the CryptoSoldiers contract
    vm.prank(address(msg.sender));
    cryptoSoldiers.changeContractOwner(address(this));
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
    assertEq(cryptoSoldiers.balanceOf(address(cryptoSoldiers)), cryptoSoldiers.totalSupply());
    assertEq(cryptoSoldiers.ownerOf(1), address(cryptoSoldiers));
    assertEq(cryptoSoldiers.ownerOf(10), address(cryptoSoldiers));
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
    assertEq(cryptoSoldiers.balanceOf(address(cryptoSoldiers)), cryptoSoldiers.totalSupply() - 1);
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

  function test_changeContractOwner() public {
    address oldOwner = cryptoSoldiers.contractOwner();
    address newOwner = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    assertNotEq(oldOwner, newOwner);
    cryptoSoldiers.changeContractOwner(newOwner);
    assertEq(cryptoSoldiers.contractOwner(), newOwner);
  }

  function testRevert_changeContractOwnerNotByContractOwner() public {
    address oldOwner = cryptoSoldiers.contractOwner();
    address newOwner = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);
    assertNotEq(oldOwner, newOwner);

    vm.expectRevert(Errors.NotContractOwner.selector);
    vm.prank(address(0xc0ffee254729296a45a3885639AC7E10F9d54979));
    cryptoSoldiers.changeContractOwner(newOwner);
  }

  function test_changeContractOwnerEvent() public {
    address oldOwner = cryptoSoldiers.contractOwner();
    address newOwner = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);

    vm.expectEmit(true, true, true, true);
    emit CryptoSoldiers.ContractOwnerChanged(oldOwner, newOwner);
    cryptoSoldiers.changeContractOwner(newOwner);
  }

  function test_transferFrom() public {
    address oldOwner = address(0xacc4166dAaB7eEA6690498D5A981307d31072ADA);
    address newOwner = address(0xc0ffee254729296a45a3885639AC7E10F9d54979);

    // setup: oldOwner buys the token from the Contract.
    vm.prank(oldOwner);
    cryptoSoldiers.buyToken(1);
    assertEq(cryptoSoldiers.ownerOf(1), oldOwner);

    vm.prank(oldOwner);
    cryptoSoldiers.transferFrom(oldOwner, newOwner, 1);
    assertEq(cryptoSoldiers.ownerOf(1), newOwner);
  }

  // function testRevert_transferFromInvalidSender() public {}
  // function testRevert_transferFromInvalidReceiver() public {}
  // function testRevert_transferFromInexistentToken() public {}
  // function testRevert_transferFromNotTokenOwner() public {}
}
