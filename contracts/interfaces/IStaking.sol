pragma solidity >=0.8.0;

interface IStaking {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function transferShare(address to, uint share) external;
    function shareToBalance(uint _share) external view returns(uint);
    function balanceToShare(uint _balance) external view returns(uint);
    function mint(uint _amount, address _to) external;
    function burn(address _to, uint256 _share) external;
}