pragma solidity ^0.5.0;

import "./vendor/Ownable.sol";
import "./interfaces/TRC20Interface.sol";

contract Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
contract JustMid is Ownable {
    TRC20Interface private token;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    constructor(address _link) public Ownable() {
        token = TRC20Interface(_link);
    }

    function getToken() public view returns (address) {
        return address(token);
    }

    function setToken(address tokenAddress)
        public
        onlyOwner
        returns (bool success)
    {
        token = TRC20Interface(tokenAddress);
        return true;
    }

    function transferAndCall(
        address from,
        address to,
        uint256 tokens,
        bytes memory _data
    ) public validRecipient(to) returns (bool success) {
        token.transferFrom(from, to, tokens);
        emit Transfer(from, to, tokens, _data);
        if (isContract(to)) {
            contractFallback(to, tokens, _data);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public validRecipient(to) returns (bool success) {
        token.transferFrom(from, to, tokens);
        return true;
    }

    function balanceOf(address guy) public view returns (uint256) {
        return token.balanceOf(guy);
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return token.allowance(src, guy);
    }

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }

    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        Receiver receiver = Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}
