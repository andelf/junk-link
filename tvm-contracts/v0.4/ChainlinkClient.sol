pragma solidity ^0.4.25;

import "./Chainlink.sol";
import "./vendor/Buffer.sol";
import "./vendor/Ownable.sol";
import "./vendor/SafeMath.sol";
import "./interfaces/JustMid.sol";
import "./interfaces/TRC20Interface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using SafeMath for uint256;

    uint256 constant internal LINK = 10 ** 18;
    uint256 constant private AMOUNT_OVERRIDE = 0;
    address constant private SENDER_OVERRIDE = 0x0;
    uint256 constant private ARGS_VERSION = 1;

    JustMid internal justMid;
    TRC20Interface internal token;
    ChainlinkRequestInterface private oracle;
    uint256 private requests = 1;
    mapping(bytes32 => address) private pendingRequests;

    event ChainlinkRequested(bytes32 indexed id);
    event ChainlinkFulfilled(bytes32 indexed id);
    event ChainlinkCancelled(bytes32 indexed id);

    /**
     * @notice Creates a request that can hold additional parameters
     * @param _specId The Job Specification ID that the request will be created for
     * @param _callbackAddress The callback address that the response will be sent to
     * @param _callbackFunctionSignature The callback function signature to use for the callback address
     * @return A Chainlink Request struct in memory
     */
    function buildChainlinkRequest(
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
    }

    /**
     * @notice Creates a Chainlink request to the stored oracle address
     * @dev Calls `chainlinkRequestTo` with the stored oracle address
     * @param _req The initialized Chainlink Request
     * @param _payment The amount of LINK to send for the request
     * @return The request ID
     */
    function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
    {
        return sendChainlinkRequestTo(oracle, _req, _payment);
    }

    /**
     * @notice Creates a Chainlink request to the specified oracle address
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send LINK which creates a request on the target oracle contract.
     * Emits ChainlinkRequested event.
     * @param _oracle The address of the oracle for the request
     * @param _req The initialized Chainlink Request
     * @param _payment The amount of LINK to send for the request
     * @return The request ID
     */
    function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
    {
        requestId = keccak256(abi.encodePacked(this, requests));
        _req.nonce = requests;
        pendingRequests[requestId] = _oracle;
        emit ChainlinkRequested(requestId);
        token.approve(justMidAddress(), _payment);
        require(justMid.transferAndCall(address(this), _oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
        requests += 1;

        return requestId;
    }

    /**
     * @notice Allows a request to be cancelled if it has not been fulfilled
     * @dev Requires keeping track of the expiration value emitted from the oracle contract.
     * Deletes the request from the `pendingRequests` mapping.
     * Emits ChainlinkCancelled event.
     * @param _requestId The request ID
     * @param _payment The amount of LINK sent for the request
     * @param _callbackFunc The callback function specified for the request
     * @param _expiration The time of the expiration for the request
     */
    function cancelChainlinkRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunc,
        uint256 _expiration
    )
    internal
    {
        ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
        delete pendingRequests[_requestId];
        emit ChainlinkCancelled(_requestId);
        requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
    }

    /**
     * @notice Sets the stored oracle address
     * @param _oracle The address of the oracle contract
     */
    function setChainlinkOracle(address _oracle) internal {
        oracle = ChainlinkRequestInterface(_oracle);
    }

    /**
     * @notice Sets the LINK token address
     * @param _link The address of the LINK token contract
     */
    function setChainlinkToken(address _link) internal {
        token = TRC20Interface(_link);
    }

    function setJustMid(address _justMid) internal {
        justMid = JustMid(_justMid);
    }

    /**
     * @notice Retrieves the stored address of the LINK token
     * @return The address of the LINK token
     */
    function justMidAddress()
    public
    view
    returns (address)
    {
        return address(justMid);
    }

    /**
     * @notice Retrieves the stored address of the oracle contract
     * @return The address of the oracle contract
     */
    function chainlinkOracleAddress()
    internal
    view
    returns (address)
    {
        return address(oracle);
    }

    /**
     * @notice Allows for a request which was created on another contract to be fulfilled
     * on this contract
     * @param _oracle The address of the oracle contract that will fulfill the request
     * @param _requestId The request ID used for the response
     */
    function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
    {
        pendingRequests[_requestId] = _oracle;
    }



    /**
     * @notice Encodes the request to be sent to the oracle contract
     * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
     * will be validated in the oracle contract.
     * @param _req The initialized Chainlink Request
     * @return The bytes payload for the `transferAndCall` method
     */
    function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
    {
        return abi.encodeWithSelector(
            oracle.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req.id,
            _req.callbackAddress,
            _req.callbackFunctionId,
            _req.nonce,
            ARGS_VERSION,
            _req.buf.buf);
    }

    /**
     * @notice Ensures that the fulfillment is valid for this contract
     * @dev Use if the contract developer prefers methods instead of modifiers for validation
     * @param _requestId The request ID for fulfillment
     */
    function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
        // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @dev Reverts if the sender is not the oracle of the request.
     * Emits ChainlinkFulfilled event.
     * @param _requestId The request ID for fulfillment
     */
    modifier recordChainlinkFulfillment(bytes32 _requestId) {
        require(msg.sender == pendingRequests[_requestId], "Source must be the oracle of the request");
        delete pendingRequests[_requestId];
        emit ChainlinkFulfilled(_requestId);
        _;
    }

    /**
     * @dev Reverts if the request is already pending
     * @param _requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 _requestId) {
        require(pendingRequests[_requestId] == address(0), "Request is already pending");
        _;
    }
}
