pragma solidity ^0.5.0;

// NOTE: This is slightly different from ERC677 and LinkTokenInterface.
interface JustMid {
    function setToken(address tokenAddress) external;

    function transferAndCall(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}
