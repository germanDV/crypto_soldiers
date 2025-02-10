// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Errors {
  /**
   * @dev Indicates that an address can't be an owner.
   * @param owner Address of the current owner of a token.
   */
  error InvalidOwner(address owner);

  /**
   * @dev Indicates a failure with the token `receiver`.
   * @param receiver Address to which tokens are being transferred.
   */
  error InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the token `sender`.
   * @param sender Address from which tokens are being transferred.
   */
  error InvalidSender(address sender);

  /**
   * @dev Indicates a `tokenId` whose `owner` is the zero address.
   * @param tokenId Identifier number of a token.
   */
  error NonexistentToken(uint256 tokenId);

  /**
   * @dev Indicates that a `tokenId` is already owned.
   * @param tokenId Identifier number of a token.
   */
  error AlreadyOwnedToken(uint256 tokenId);

  /**
   * @dev Indicates an error related to the ownership over a particular token.
   * @param sender Address whose tokens are being transferred.
   * @param tokenId Identifier number of a token.
   * @param owner Address of the current owner of a token.
   */
  error IncorrectOwner(address sender, uint256 tokenId, address owner);

  /**
   * @dev Indicates a failure with the `operator` to be approved.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   */
  error InvalidOperator(address operator);
}
