pragma solidity >=0.8.0 <0.9.0;

contract A {
    struct Deployment {
        address bAddr;
        uint256 index;
        string title;
    }

    Deployment[] public deployments;

    event NewB(address indexed b, uint256 indexed index, string title);

    function deployB(uint256 index, string memory title) external {
        B b = new B(index, title);
        deployments.push(Deployment(address(b), index, title));
        
        emit NewB(address(b), index, title);
    }
}

contract B {
    uint256 public index;
    string public title;

    constructor(uint256 _index, string memory _title) {
        index = _index;
        title = _title;
    }
}
