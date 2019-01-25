## Building
Run `make`

## Usage
`./fibonacci <0 .. n .. 100> [-o]`

## Description
Fibonacci accepts a single positive command line parameter to use as an index into the fibonacci sequence. The output is the number at that position in the sequence. If the -o flag is present, the output will be displayed in octal.

## Examples
```bash
./fibonacci 15      # Decimal input
./fibonacci -o 50   # Decimal input, octal output
./fibonacci 0x64 -o # Octal output, hex input
./fibonacci 010     # Octal input
```
