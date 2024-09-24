pragma solidity >=0.8.0 <0.9.0;

contract B {
    uint256 public index;
    string public title;

    constructor(uint256 _index, string memory _title) public {
        index = _index;
        title = _title;
    }
}