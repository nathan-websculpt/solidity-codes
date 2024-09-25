pragma solidity >=0.8.0 <0.9.0;

contract A {
    struct Deployment {
        address bAddr;
        uint256 index;
        string title;
    }

    Deployment[] public deployments;

    event NewB(address indexed b, uint256 indexed index);

    function deployB(uint256 index, string memory title) external {
        bytes32 eventSig = keccak256("NewB(address,uint256)");
        assembly {
            let f_mem := mload(0x40) // load free memory pointer
            mstore(f_mem, index) 
            mstore(add(f_mem, 0x20), title)
            // create a new contract using the code at memory location 0x20
            let b := create(0, 0x40, 0x1000)
            // add the new contract to the deployments array
            // let deploymentsSlot := deployments.slot
            // mstore(add(deploymentsSlot, 0x40), b) // set bAddr
            // mstore(add(deploymentsSlot, 0x60), index) // set index
            // mstore(add(deploymentsSlot, 0x80), title) // set title

            log3(0, 0, eventSig, b, index) // Emit event
        }
    }
}

contract B {
    uint256 public index;
    string public title;

    constructor() {
        assembly {
            // set the index and title
            sstore(0, mload(0x80))
            sstore(1, mload(0x80))
        }
    }
}
