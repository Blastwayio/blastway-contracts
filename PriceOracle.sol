// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";
import "./PythPriceOracle.sol";
import "./Ownership/Ownable.sol";

contract PriceOracle is Ownable {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    Pyth public oracle;

    mapping (address => bytes32) public getPythFeedIdFromAddress;
    mapping (address => uint) public getUnderlyingDecimalsFromAddress;

    constructor(address pythOracleAddress) {
      oracle = Pyth(pythOracleAddress);
    }

    function setPythFeedIds(address[] memory tokenAddresses, bytes32[] memory feedIds) public onlyOwner {
      require(tokenAddresses.length == feedIds.length, "Arrays must have the same length");

      for (uint i = 0; i < tokenAddresses.length; i++) {
        getPythFeedIdFromAddress[tokenAddresses[i]] = feedIds[i];
      }
    }

    function setUnderlyingDecimals(address[] memory tokenAddresses, uint[] memory decimals) public onlyOwner {
      require(tokenAddresses.length == decimals.length, "Arrays must have the same length");

      for (uint i = 0; i < tokenAddresses.length; i++) {
        getUnderlyingDecimalsFromAddress[tokenAddresses[i]] = decimals[i];
      }
    }

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external view returns (uint256) {
      bytes32 pythPriceFeedId = getPythFeedIdFromAddress[address(cToken)];
      PythStructs.Price memory priceData = oracle.getPriceUnsafe(pythPriceFeedId);

      uint256 price = uint256(uint64(priceData.price));
      uint256 feedDecimals = 8;
      uint underlyingDecials = getUnderlyingDecimalsFromAddress[address(cToken)];

      return price * 10**(36 - feedDecimals - underlyingDecials);
    }
}