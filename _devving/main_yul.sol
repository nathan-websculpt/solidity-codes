pragma solidity >=0.8.0 <0.9.0;

contract A {
    // each field in the struct will occupy 32 bytes
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
            // create a new contract using the code at memory location 0x20
            let b := create(0, 0x40, 0x1000)
            // add the new contract to the deployments array
            // let deploymentsSlot := deployments.slot
            // mstore(add(deploymentsSlot, 0x40), b) // set bAddr
            // mstore(add(deploymentsSlot, 0x60), index) // set index
            // mstore(add(deploymentsSlot, 0x80), title) // set title


            // Push struct to array a different way
            pushToArray(bAddr, index, title)

            log3(0, 0, eventSig, b, index) // Emit event
        }
    }

    function pushToArray(
        address bAddr,
        uint256 index,
        string title
    ) public pure returns (uint256, uint256, uint256) {
        assembly {
            // Allocate memory for array
            let arrayPtr := mload(0x40)

            // Get current length (0 if first push)
            let length := mload(arrayPtr)

            // Calculate new length
            let newLength := add(length, 1)

            // Store new length
            mstore(arrayPtr, newLength)

            // Calculate offset for new struct
            let offset := add(arrayPtr, mul(add(length, 1), 0x20))

            // Store struct fields
            mstore(offset, bAddr)
            mstore(add(offset, 0x20), index)
            mstore(add(offset, 0x40), title)

            // Update free memory pointer!!
            mstore(0x40, add(offset, 0x40))

            // Return array pointer, new length, and offset of new struct
            return(0, 0x60)
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
