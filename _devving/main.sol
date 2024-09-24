pragma solidity >=0.8.0 <0.9.0;

contract Main {
    address public contractA;

    constructor() public {
        contractA = address(0);
    }

    function setContractA(address _contractA) public {
        require(contractA == address(0), "Contract A already set");
        contractA = _contractA;
    }

    modifier onlyContractA() {
        require(msg.sender == contractA, "Only Contract A can call this function");
        _;
    }
}

