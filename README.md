# junk-link

A Chainlink fork is a piece of cake, while ugly code always sucks.

## Compile

```sh
cd ./tvm-contracts/v0.5
mkdir -p out/
solc --overwrite --allow-paths . -o out/ --abi --bin Oracle.sol
solc --overwrite --allow-paths . -o out/ --abi --bin SimpleConsumer.sol
```
