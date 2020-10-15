pragma solidity ^0.4.25;

interface JustMid {
    function setToken(address tokenAddress) external;

    function transferAndCall(
        address from,
        address to,
        uint256 tokens,
        bytes _data
    ) external returns (bool success);

    function balanceOf(address guy) external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function allowance(address src, address guy)
        external
        view
        returns (uint256);
}
