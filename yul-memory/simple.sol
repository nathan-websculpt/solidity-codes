pragma solidity >=0.8.0 <0.9.0;

contract MemTest {
    function test() external view {
        bytes32 freeMemory;

        string memory tstStr = "hello";


        assembly {
            let f_mem := mload(0x40) // load free memory pointer
            mstore(f_mem, 32) // store 32 at free memory pointer
        }
    }
}
