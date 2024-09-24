pragma solidity >=0.8.0 <0.9.0;

// log3(p, s, t1, t2, t3) -> data of size s, starting at memory slot p - w/ topics t1, t2, t3

// The first and second param denote the area of memory to return as the non-indexed
// arguments. If you are not indexing any arguments, set this to 0

// The first topic, t1, is the hash of the event signature
// The second topic, t2, is the indexed data 'a'
// The second topic, t3, is the indexed data 'b'

contract YulSimple {
    event EventOne(uint256 indexed a, uint256 indexed b);
    event EventTwo(uint256 indexed foo, uint256 bar);

    function yulEventOne() public {
        bytes32 signature = keccak256("EventOne(uint256,uint256)");
        assembly {
            log3(0, 0, signature, 999, 888)
        }
    }

    function yulEventTwo() public {
        bytes32 signature = keccak256("EventTwo(uint256,uint256)");
        assembly {
            // non-indexed values have to first be stored into memory
            mstore(0x00, 0x22) // store 34 at address 0x00
            // memory area is used as params to the logN function
            // to emit the non-indexed values as part of the event
            log2(0x00, 0x20, signature, 777)
        }
    }
}
