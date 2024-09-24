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

    //testing ... returns string: 'hello'
    function hello() public pure returns (string memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, 0x5)
            mstore(
                0x40,
                0x68656c6c6f000000000000000000000000000000000000000000000000000000
            )
            return(0x00, 0x60)
        }
    }
}

contract B {
    uint256 public index;
    string public title;

    constructor(uint256 _index, string memory _title) {
        assembly {
            // set the index and title
            sstore(0, _index)
            sstore(1, _title)
        }
    }
}
