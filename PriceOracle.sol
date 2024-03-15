// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";
import "./PythPriceOracle.sol";
import "./Ownership/Ownable.sol";

contract PriceOracle is Ownable {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;
    uint256 public freshnessThreshold = 60;

    Pyth public oracle;

    mapping (address => bytes32) public getPythFeedIdFromAddress;

    constructor(address pythOracleAddress) {
      oracle = Pyth(pythOracleAddress);
    }

    function setPythFeedIds(address[] memory tokenAddresses, bytes32[] memory feedIds) public onlyOwner {
      require(tokenAddresses.length == feedIds.length, "Arrays must have the same length");

      for (uint i = 0; i < tokenAddresses.length; i++) {
        getPythFeedIdFromAddress[tokenAddresses[i]] = feedIds[i];
      }
    }

    function setFreshnessThreshold(uint256 _freshnessThreshold) public onlyOwner {
      freshnessThreshold = _freshnessThreshold;
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
      require(block.timestamp - priceData.publishTime <= freshnessThreshold, "Stale prices");

      return convertToUint(priceData, 18);
    }

    function convertToUint(
      PythStructs.Price memory price,
      uint8 targetDecimals
    ) private pure returns (uint256) {
      if (price.price < 0 || price.expo > 0 || price.expo < -255) {
        revert();
      }

      uint8 priceDecimals = uint8(uint32(-1 * price.expo));

      if (targetDecimals >= priceDecimals) {
        return
          uint(uint64(price.price)) *
          10 ** uint32(targetDecimals - priceDecimals);
      } else {
        return
          uint(uint64(price.price)) /
          10 ** uint32(priceDecimals - targetDecimals);
        }
    }
}