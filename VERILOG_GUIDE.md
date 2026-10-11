# Verilog Syntax Guide for the RV32I Processor

This guide explains the Verilog patterns used in this repository in plain language. The goal is not just to read the code, but to be able to explain **what each construct means, why it is used, and what hardware or simulation behavior it describes**.

Examples are taken from the style of this project. You can keep this file open while reading `rtl/` and `tb/`.

## 1. The big picture: what is Verilog?

Verilog is a language for describing digital circuits. You can use it to describe both:

- **Hardware behavior**: wires, arithmetic units, registers, memory, and how signals connect.
- **Simulation behavior**: test inputs, wait for clock edges, check results, print messages, and save waveforms.

A Verilog description is not usually a list of instructions that a processor executes like a software program. It describes circuit parts that work together. Some statements describe connections that continuously respond to changes; other blocks describe what should happen when an event, such as a clock edge, occurs.

### Two broad kinds of code in this repository

| Style | Example | What it does |
| --- | --- | --- |
| Combinational logic | `always @(*)` or `assign` | Produces an output from the current inputs |
| Clocked logic | `always @(posedge clk)` | Updates stored state on a rising clock edge |

The ALU and control unit mostly use combinational logic. The program counter and register file use clocked logic to retain values from one cycle to the next.

## 2. Modules: the building blocks

A `module` defines one circuit block. Think of a module like a component with named inputs and outputs.

A small example:

```verilog
module Example(
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] sum
);
    assign sum = a + b;
endmodule
```

- `module Example(...);` starts a module called `Example`.
- `input` means a signal enters the module.
- `output` means a signal leaves it.
- `endmodule` ends the module.

This example has two 32-bit inputs and one 32-bit output. It continuously makes `sum` equal to `a + b`.

### The two port styles in this project

Some modules use the modern, compact form shown above (for example, `Top.v`). Others list port names first and declare them below:

```verilog
module ProgramCounter(clk, reset, PC_in, PC_out);
input clk;
input reset;
input [31:0] PC_in;
output reg [31:0] PC_out;
...
endmodule
```

These are two ways to write module ports. The second style is older but still valid Verilog. The words `input`, `output`, and the widths give the ports their direction and size.

### Connecting modules together

In `Top.v`, the processor connects smaller blocks using module instances:

```verilog
ALU alu (
    .A(ALU_A),
    .B(ALU_B),
    .ALUControl_in(ALUControlOut),
    .ALU_result(ALU_result),
    .zero(ALU_zero)
);
```

- `ALU` is the module type.
- `alu` is the name of this particular instance.
- `.A(ALU_A)` means the ALU port named `A` is connected to the signal named `ALU_A` in `Top`.

Named connections are useful because they make it clear which signal goes to which port. A module definition is like a component design; an instance is that component placed into the larger processor.

## 3. Signals: `wire` versus `reg`

This is one of the most important differences to understand.

### `wire`: a connection

A `wire` represents a signal driven by a continuous assignment or by another module's output.

```verilog
wire [31:0] pc_plus4;
assign pc_plus4 = PC_out + 32'd4;
```

Whenever `PC_out` changes, `pc_plus4` reflects the new `PC_out + 4`. The wire does not remember a past value by itself.

### `reg`: a variable assigned inside a procedural block

In classic Verilog, a signal assigned from inside an `always` or `initial` block is generally declared as `reg`.

```verilog
output reg [31:0] PC_out;
```

**Important:** `reg` does not automatically mean “a physical register.” It describes the kind of variable used by the Verilog language. The code that assigns it determines what hardware behavior is inferred.

For example:

- `reg` assigned in `always @(*)` can describe **combinational logic**.
- `reg` assigned in `always @(posedge clk)` describes **clocked storage**, such as a hardware register.

The `ControlUnit` outputs are declared `reg` because the `always @(*)` block assigns them. They are combinational outputs, not clocked registers.

### A simple comparison

| Declaration / use | Meaning in this project |
| --- | --- |
| `wire x;` | A signal connection, commonly driven by `assign` or a module output |
| `reg x;` | A procedural variable, assigned in an `always` or `initial` block |
| `output wire x` | An output driven continuously or by a connected module |
| `output reg x` | An output assigned in a procedural block |

SystemVerilog also has `logic`, which is commonly used in newer code. This repository mostly uses classic Verilog `wire` and `reg` declarations.

## 4. Bit widths and number formats

Hardware signals have a defined number of bits. A range such as `[31:0]` contains both endpoints, so it is **32 bits wide**.

```verilog
wire [31:0] instruction; // 32 bits
wire [4:0]  rs1;         // 5 bits
wire [2:0]  func3;       // 3 bits
```

The left number is the most significant bit (MSB); the right number is the least significant bit (LSB).

### Reading numeric literals

Verilog literals often look like `32'd4` or `7'b1100111`:

| Example | Meaning |
| --- | --- |
| `32'd4` | The decimal number 4, written with a width of 32 bits |
| `7'b1100111` | A 7-bit binary number |
| `32'h12345000` | A 32-bit hexadecimal number |
| `12'hFFF` | A 12-bit hexadecimal number |
| `1'b0` | A one-bit zero |
| `32'b0` | A 32-bit value of all zeroes |

The character after the apostrophe tells the number base: `b` for binary, `d` for decimal, `h` for hexadecimal, and `o` for octal. The number before the apostrophe gives the width.

Hexadecimal digits represent four bits each. That is why a 32-bit value is often shown with eight hexadecimal digits.

### Selecting bits

```verilog
assign opcode = instruction[6:0];
assign rd     = instruction[11:7];
assign func3  = instruction[14:12];
```

`instruction[6:0]` means bits 6 down to 0. A single bit can be selected as `instruction[31]`.

This is how `Top.v` separates the instruction's fields into signals that other modules can use.

## 5. Continuous assignment: `assign`

Use `assign` for a continuous connection or expression:

```verilog
assign ALU_B = ALUScr ? immediate : Read_data2;
```

This says: keep `ALU_B` equal to `immediate` when `ALUScr` is 1; otherwise keep it equal to `Read_data2`.

The assignment reacts whenever a value it depends on changes. It is not waiting for a clock edge.

The `?:` operator is called the **conditional** or **ternary** operator:

```verilog
condition ? value_if_true : value_if_false
```

It is a compact way to choose between two values. In `Top.v`, similar expressions choose the next PC and the value to write back.

## 6. Combinational logic: `always @(*)`

A combinational block calculates outputs from current inputs. It does not intentionally remember previous results.

```verilog
always @(*) begin
    result = 32'b0;

    case (operation)
        2'b00: result = a + b;
        2'b01: result = a - b;
        default: result = 32'b0;
    endcase
end
```

- `always` means the block runs again whenever its sensitivity event occurs.
- `@(*)` means the simulator should react to changes in signals read by the block. This avoids manually listing each signal.
- `begin` and `end` group multiple statements into one block.
- `case` chooses a path based on a value.
- `default` handles values not listed above.

The ALU and control unit use this style.

### Why safe defaults matter

The `ControlUnit` begins by assigning default values to every control output and then changes the ones needed by the current instruction. This means an unsupported encoding still has defined output values.

In combinational logic, outputs should be assigned on every possible path. If an output is left unassigned on some paths, the design may infer a latch (a storage element that keeps an old value). A default assignment at the beginning of the block is a common way to avoid that problem.

### `if`, `else`, and `case`

```verilog
if (reset) begin
    PC_out <= 32'b0;
end
else begin
    PC_out <= PC_in;
end
```

This chooses between two alternatives. `if` checks a condition; `else` is used when the condition is not true.

Use `case` when choosing among several instruction opcodes, ALU operations, or function fields. Include a `default` when unlisted values need a defined behavior.

## 7. Clocked logic and clock edges

The processor must remember the current instruction address and the values written to its registers. Clocked logic updates that state at a chosen clock edge.

```verilog
always @(posedge clk) begin
    if (reset)
        PC_out <= 32'b0;
    else
        PC_out <= PC_in;
end
```

- `posedge clk` means the block runs when `clk` changes from 0 to 1.
- `reset` makes the PC return to address zero.
- Otherwise, the PC stores `PC_in`.
- `<=` is a non-blocking assignment, explained next.

This is the core of `ProgramCounter.v`. The register file similarly writes a register on a rising clock edge, when `RegWrite` is enabled.

## 8. Blocking `=` versus non-blocking `<=`

Both symbols assign values, but they have different timing rules inside procedural code. Choose the right one based on whether you are describing combinational behavior or clocked state updates.

### Blocking assignment: `=`

A blocking assignment takes effect immediately for the rest of the current procedural block.

```verilog
always @(*) begin
    temp = a + b;
    result = temp * 2;
end
```

The second line uses the value of `temp` assigned by the first line. This is the common style for combinational logic in this repository.

### Non-blocking assignment: `<=`

A non-blocking assignment evaluates its right-hand side when the statement runs, then schedules its left-hand side to update later in the current simulation time step. Other non-blocking updates in that time step are handled together. This is useful for clocked state because it models values updating together at a clock edge.

```verilog
always @(posedge clk) begin
    first  <= input_value;
    second <= first;
end
```

After a rising edge:
- `first` receives the old value of `input_value` sampled at that edge.
- `second` receives the **old** value of `first`, not the new value being assigned to `first` on the same edge.

This is exactly the behavior expected from two cascaded hardware registers.

### Easy rule for this project

- Use **blocking `=`** in combinational `always @(*)` blocks.
- Use **non-blocking `<=`** in clocked `always @(posedge clk)` blocks.

That is the convention followed by the main sequential logic here.

## 9. Operators you will see in the code

### Arithmetic and comparison

| Operator | Meaning | Example |
| --- | --- | --- |
| `+` | Addition | `PC_out + 32'd4` |
| `-` | Subtraction | `A - B` |
| `==` | Equality comparison | `rs1_data == rs2_data` |
| `!=` | Not equal | `rs1_data != rs2_data` |
| `<`, `>=` | Less than, greater than or equal | Branch comparisons |
| `&&`, `||` | Logical AND, logical OR | `jump || jalr` |
| `!` | Logical NOT | `!reset` |

### Bitwise and shift operators

| Operator | Meaning |
| --- | --- |
| `&` | AND each corresponding bit |
| `|` | OR each corresponding bit |
| `^` | XOR each corresponding bit |
| `~` | Flip each bit (0 becomes 1, 1 becomes 0) |
| `<<` | Shift bits left |
| `>>` | Shift bits right, filling with zeroes |
| `>>>` | Arithmetic right shift; fills from the sign bit when the left operand is signed |

A logical operator typically answers a yes/no question about whole expressions. A bitwise operator works across the individual bits of a vector.

### Signed versus unsigned

A 32-bit pattern such as `32'hFFFFFFFF` can represent unsigned 4,294,967,295 or signed -1, depending on how it is interpreted.

The branch comparator uses `$signed(...)` for signed comparisons:

```verilog
$signed(rs1_data) < $signed(rs2_data)
```

The system function `$signed(...)` tells Verilog to interpret that value as signed for the expression. Unsigned comparisons, such as BLTU and BGEU, compare the values without that signed interpretation.

### Exact test comparisons: `!==`

Testbenches often use `!==` rather than `!=`. Verilog can represent unknown (`X`) and high-impedance (`Z`) bits in simulation. `!==` compares those states exactly, so a result containing an unexpected `X` does not accidentally pass a test.

## 10. Concatenation and sign extension

Curly braces `{ }` join bit groups together into one larger vector.

```verilog
assign jalr_target = {ALU_result[31:1], 1'b0};
```

This creates a 32-bit target from bits 31 through 1 of `ALU_result`, followed by a zero in bit 0. That clears the least-significant bit.

Braces can also repeat bits. For example:

```verilog
{{20{instruction[31]}}, instruction[31:20]}
```

- `{20{instruction[31]}}` repeats the instruction's sign bit 20 times.
- The next part, `instruction[31:20]`, adds the 12-bit immediate.
- Together these make a 32-bit signed immediate.

If the immediate's most-significant bit is 0, the upper bits become zero. If it is 1, the upper bits become one. This is called **sign extension** and allows a small signed number to be used in 32-bit arithmetic.

## 11. Arrays and memory

A declaration such as:

```verilog
reg [31:0] memory [0:255];
```

means a memory array with 256 entries, each 32 bits wide. The first range, `[31:0]`, is the width of each entry; the second, `[0:255]`, is the range of entry indices.

The instruction memory loads the sample program using:

```verilog
$readmemh("programs/instructions.mem", memory);
```

`$readmemh` is a simulator/system task that reads hexadecimal values from a text file into a memory array. In this project, it allows the instructions to be changed without rewriting the instruction-memory module.

The register file is another array:

```verilog
reg [31:0] registers [31:0];
```

It represents 32 registers with 32 bits each. This design treats register `x0` specially: reads from `x0` return zero, and writes to `x0` are ignored.

## 12. Loops, counters, and temporary variables

The following pattern appears when clearing an array:

```verilog
integer i;

for (i = 0; i < 256; i = i + 1)
    memory[i] = 32'b0;
```

- `integer i;` declares an integer variable, often used as a loop counter in simulation and RTL.
- `i = 0` initializes the loop counter.
- `i < 256` is the condition that keeps the loop running.
- `i = i + 1` increments it after each pass.

This loop visits each memory entry from 0 through 255. The loop does not mean the processor takes 256 clock cycles to clear this simulation memory; it runs as part of the block in which it appears.

## 13. Testbench syntax

A **testbench** is a small simulation program that drives a module's inputs and checks its outputs. It is not hardware intended to be synthesized into the processor.

### `initial`: do something once

```verilog
initial begin
    reset = 1'b1;
    #10;
    reset = 1'b0;
end
```

An `initial` block starts at the beginning of simulation and runs once. The example asserts reset, waits ten simulation time units, then deasserts it.

### Clock generation with `always` and `#`

```verilog
always #5 clk = ~clk;
```

`#5` waits five simulation time units. `~clk` flips the one-bit clock: 0 becomes 1, and 1 becomes 0. Repeating this produces a clock with a ten-unit period.

The timescale directive controls how delay numbers and displayed time are interpreted:

```verilog
`timescale 1ns/1ps
```

Here, `#1` means one nanosecond, and the simulation precision is one picosecond. The actual design's clock period is determined by the testbench clock generator.

### Waiting for events

```verilog
@(posedge clk);
#1;
```

The testbench waits for the next rising edge, then waits a little longer before checking values. That small delay gives non-blocking assignments from the edge time to update before the assertion runs.

### Tasks: reusable test steps

A task groups commands so a testbench can repeat a common operation. This project also passes descriptive test names into tasks. In classic Verilog, these names may be stored in a fixed-width packed vector (for example, `input [255:0] test_name`) and printed with `%0s`. That is a way to carry text in older Verilog style, rather than a modern SystemVerilog `string` variable:

```verilog
task check_result;
    input [31:0] expected;
    begin
        #1;
        if (result !== expected)
            $fatal(1, "Result mismatch");
    end
endtask
```

Calling `check_result(32'd23)` runs the statements inside the task with 23 as the expected value. The control-unit and immediate-generator testbenches use this idea to avoid repeating the same comparison code many times.

### Repeating an event or a statement

This project sometimes uses:

```verilog
repeat (2) @(posedge clk);
```

It waits for two rising clock edges. `repeat (2)` means perform the following statement two times, and `@(posedge clk)` means wait until the clock changes from 0 to 1 each time. This is different from `#10`, which waits for ten simulation time units regardless of where the clock is.

### Testbench messages and checks

| Construct | Purpose |
| --- | --- |
| `$display(...)` | Print a message at that moment |
| `$monitor(...)` | Print a line whenever one of its listed values changes |
| `$fatal(...)` | Report a fatal test failure and stop the simulation |
| `$finish` | End the simulation normally |
| `$dumpfile("wave.vcd")` | Choose the waveform filename |
| `$dumpvars(0, testbench_name)` | Record signals into the waveform |

These are simulation system tasks, indicated by the leading `$`. They help a testbench report whether the design behaved as expected and make signal activity available for waveform inspection.

### Formatting values in messages

A format marker in a message tells Verilog how to print the value supplied for it:

| Marker | Prints the value as | Example use |
| --- | --- | --- |
| `%b` | Binary | An opcode or control signal |
| `%d` | Decimal | A register number or count |
| `%h` | Hexadecimal | A 32-bit instruction or result |
| `%s` | Text | A test name |
| `%t` | Simulation time | The current simulation timestamp |
| `%0d`, `%0s`, `%0t` | Decimal, text, or time with compact formatting | Common in this project's test messages |

The values after the format string are matched to the markers in order. For example, `$display("Result = %h", result);` prints `result` in hexadecimal. The `0` in `%0t` or `%0s` asks the simulator to avoid unnecessary leading padding.

### Inspecting internal signals in a testbench

The top-level testbench uses a reference such as:

```verilog
dut.register_file.registers[1] = 32'd20;
```

- `dut` is the instance name used for the processor under test.
- `register_file` is an instance inside `Top`.
- `registers[1]` is entry 1 of that instance's register array.

This is **hierarchical reference**: the testbench reaches into the simulated design to set or inspect an internal signal. It is convenient for learning and controlled tests, but it is not a normal way for real software to access processor registers. The current top smoke test uses it to seed `x1` and `x2`; the program does not itself set those values.

## 14. Comments and formatting

```verilog
// A single-line comment.

/*
   A multi-line
   comment.
*/
```

Comments explain intent and are ignored by the hardware description. Use them to explain why a signal or choice exists, especially where the reason is not obvious.

Indent nested `begin/end` blocks, use meaningful names, and keep one module focused on one job. Those habits make hardware easier to review and test.

## 15. A worked example: `ADD x3, x1, x2`

The first word in `programs/instructions.mem` is:

```text
002081B3  // ADD x3, x1, x2
```

The top-level smoke test sets `x1 = 20` and `x2 = 3` through the testbench, then allows this instruction to execute.

1. **Fetch:** The PC starts at 0, so instruction memory reads the word at address 0.
2. **Decode:** `Top` extracts the opcode and register fields. The control unit recognizes an R-type ADD and enables register write-back.
3. **Read:** The register file provides 20 from `x1` and 3 from `x2`.
4. **Execute:** The ALU is told to add, so its result is 23.
5. **Select result:** This instruction is not a load or jump, so the write-back path selects the ALU result.
6. **Clock edge:** If `RegWrite` is enabled and the destination is not `x0`, the register file writes 23 to `x3`. The PC advances from 0 to 4.

After the edge, the expected result is `x3 = 23`, and the PC points to the next instruction. The testbench checks the value of `x3`; if it is not 23, `$fatal` reports a failure.

This simple example demonstrates how instruction memory, decoding, the register file, the ALU, write-back selection, and the PC cooperate to carry out one instruction.

## 16. Quick mental checklist when reading a module

When you open a Verilog file, ask these questions in order:

1. **What are the inputs and outputs?** Find the `module` declaration and port list.
2. **Which signals are connections and which are procedural variables?** Look for `wire` and `reg`.
3. **What makes the logic run?** Look for `assign`, `always @(*)`, `always @(posedge clk)`, or `initial`.
4. **Does it remember state?** Clock-edge logic usually does; complete combinational logic usually does not.
5. **Where are values selected or checked?** Look for `if`, `case`, operators, and `?:`.
6. **How is it tested?** Find the matching testbench and see which values are checked.

If you can answer those six questions, you can usually explain the purpose of a module before diving into every line.

---

For the overall architecture, instruction list, project layout, and simulation commands, see [README.md](README.md).
