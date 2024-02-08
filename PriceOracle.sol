// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";
import "./PythPriceOracle.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    Pyth public oracle;

    constructor(address pythOracleAddress) {
      oracle = Pyth(pythOracleAddress);
    }

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external view returns (uint256) {
      bytes32 pythPriceFeedId = cToken.pythPriceFeedId();
      PythStructs.Price memory priceData = oracle.getPriceUnsafe(pythPriceFeedId);

      uint256 price = uint256(uint64(priceData.price));
      uint256 feedDecimals = 8;

      return price * 10**(18 - feedDecimals);
    }
}