## Running and testing opcodes



##### The Ethereum Virtual Machine (EVM) is a stack-based VM that has a relatively small instruction-set that run as opcodes

#### There are three main parts to the EVM to know about

- STACK
- MEMORY
- STORAGE

#### Examples

[Run in EVM Codes playground](https://www.evm.codes/playground) with the mnemonic tab selected

```
push1 0x01 // stack: [1]
push1 0x02 // stack: [2, 1]
push1 0x03 // [3, 2, 1]

swap2      // [1, 2, 3]

```

```
push1 0x01 // stack: [1]
push1 0x02 // stack: [2, 1]
push1 0x03 // [3, 2, 1]
dup1       // [3, 3, 2, 1]
pop        // [3, 2, 1]

swap2      // [1, 2, 3]

```

```
push1 0x01   // [1]
push1 0x02   // [2, 1]
  
add          // [3] 
  
push1 0x02   // [2, 3]
dup2         // [3, 2, 3]
  
mul          // [6, 3]
  
div          // [2]
  
pop          // []

```

```
// store timestamp at slot zero

timestamp     // [block_timestamp]
push1 0       // [zero, block_timestamp]
sstore        // []

```


```
// see if caller is owner of contract
// assuming owner's address is stored at slot 0x00

caller        // [caller_address]

push1 0       // [zero, caller_address]
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