pragma solidity >=0.8.0 <0.9.0;

contract A {
    event NewB(address indexed b, uint256 indexed index);

    function deployB(uint256 index) external {
        bytes32 eventSig = keccak256("NewB(address,uint256)");

        bytes memory bytecode = type(B).creationCode;
        bytes memory encodedParams = abi.encode(index);
        bytes memory combinedCode = abi.encodePacked(bytecode, encodedParams);

        assembly {
            let size := mload(combinedCode)
            let ptr := add(combinedCode, 0x20)
            let b := create(0, ptr, size)

            log3(0, 0, eventSig, b, index) // Emit event
        }
    }
}

contract B {
    uint256 public index;
    constructor(uint256 _index) {
        index = _index;
    }
}
