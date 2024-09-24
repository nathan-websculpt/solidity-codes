pragma solidity >=0.8.0 <0.9.0;

import "./Main.sol";

contract A {
    Main public main;
    mapping(uint256 => address) public contractBs;

    constructor(address _main) public {
        main = Main(_main);
        main.setContractA(address(this));
    }

    function deployB(uint256 _index, string memory _bookTitle) public {
        B b = new B(_index, _bookTitle);
        contractBs[_index] = address(b);
        emit NewB(address(b), _index, _bookTitle);
    }

    event NewB(address indexed b, uint256 indexed index, string title);
}