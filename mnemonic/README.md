## Running and testing opcodes

[Run in EVM Codes playground](https://www.evm.codes/playground) with the mnemonic tab selected

#### Examples

```
// store timestamp at slot zero

timestamp     // [block_timestamp]
push1 0×00    // [zero, block_timestamp]
sstore        // []

```


```
// see if caller is owner of contract
// assuming owner's address is stored at slot 0x00

caller        // [caller_address]

push1 0×00    // [zero, caller_address]
sload         // [owner_address, caller_address]

eq            // [is_caller_owner]

```

```
push1 0x01 // [1]
push1 0x00 // [0, 1]

// store one in memory starting at slot zero

mstore

push1 0x00 // [0]

// load from memory starting at slot one ... pushes value back onto the stack

mload      // [1]
```