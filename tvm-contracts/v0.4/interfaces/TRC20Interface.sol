pragma solidity ^0.4.25;

// TRON TRC20
interface TRC20Interface {

  function totalSupply() external view returns (uint);
  function balanceOf(address guy) external view returns (uint);
  function allowance(address src, address guy) external view returns (uint);
  function approve(address guy, uint wad) external returns (bool);
  function transfer(address dst, uint wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
