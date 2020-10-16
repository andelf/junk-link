pragma solidity ^0.5.0;

import "./ChainlinkClient.sol";
import "./vendor/Ownable.sol";

/**
 * @title An example Chainlink contract, SimpleConsumer
 * @notice Requesters can use this contract as a framework for creating
 * requests to multiple Chainlink nodes and running aggregation
 * as the contract receives answers.
 */
contract SimpleConsumer is ChainlinkClient, Ownable {
    // using SignedSafeMath for int256;

    uint256 public value;

    // address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    /**
     * @notice Deploy with the address of the LINK token and arrays of matching
     * length containing the addresses of the oracles and their corresponding
     * Job IDs.
     * @dev Sets the LinkToken address for the network, addresses of the oracles,
     * and jobIds in storage.
     * @param _link The address of the LINK token
     * @param _justMid The address of the JustMid token
     */
    constructor(address _link, address _justMid) public {
        setChainlinkToken(_link);
        setJustMid(_justMid);
        // TYZxQSHAhxGgUWzxYEZAohvWc9cQWXtNBt
        setChainlinkOracle(0xF7e52418572834722ED87E9425d673FEdBD55a0e);

        // 32 bytes
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        fee = 0.001 * 10**18; // 0.001 JST
    }

    function requestNewData() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        // Sends the request
        return sendChainlinkRequest(request, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _value)
        public
        recordChainlinkFulfillment(_requestId)
    {
        value = _value;
    }
}
