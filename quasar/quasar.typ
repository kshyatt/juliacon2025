#import "@preview/typslides:1.2.5": *

#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
)

#front-slide(
  title: "Quasar.jl",
  subtitle: [A Julia parser for OpenQASM 3],
  authors: "Katharine Hyatt",
  info: [#link("https://github.com/kshyatt")],
)

//#table-of-contents()

#slide(title: "The quantum IR landscape")[
  - An intermediate representation (IR) is a middle layer between
  - Multiple competing standards for low-level instruction set for quantum computing
  - Two of the most common are *OpenQasm* and *Quake*
]

#slide(title: "Quake")[
  - Open standard, developed by a consortium inc. NVIDIA and MSFT
  - Aims to support a variety of hardware targets and low-level pulse programming
  - Compatible with MLIR
]

#slide(title: "OpenQASM")[
  - Open standard, developed and maintained mostly by IBM
  - Aims to support a variety of hardware targets and low-level pulse programming
  - Not compatible with MLIR
]

#slide(title: "Developing a good quantum IR is hard")[
  - Every quantum computing platform has different native gates, if it supports gates at all
  - No one knows what the "final form" of quantum programming will be like
  - We're trying to develop `x86-64` or `arm64` in 1952
  - We want *both* low-level device control (pulses) and higher level abstractions
]

#slide(title: "OpenQASM features")[
  #cols(columns: (2fr, 1fr), gutter: 2em)[
  - Custom gate definitions & gate modifiers
  - Qubit arrays
  - Weird indexing behavior
    - You can index the bits of any number!
  - Splatting across qubit arguments
  - Combination of Pythonic and C-like semantics
][
```
gate sdg a {
  inv @ pow(0.5) @ z a;
}
```
]
]
#slide(title: "OpenQASM features")[
  #cols(columns: (2fr, 1fr), gutter: 2em)[
  - Custom gate definitions & gate modifiers
  - Qubit arrays
  - Weird indexing behavior
    - You can index the bits of any number!
  - Splatting across qubit arguments
  - Combination of Pythonic and C-like semantics
][
```
qubit[4] q1;
qubit[3] q2;
let q = q1 ++ q2;
```
]
]

#slide(title: "OpenQASM features")[
  #cols(columns: (2fr, 1fr), gutter: 2em)[
  - Custom gate definitions & gate modifiers
  - Qubit arrays
  - Weird indexing behavior
    - You can index the bits of any number!
  - Splatting across qubit arguments
  - Combination of Pythonic and C-like semantics
][
```
uint[4] a = 15; # 1111
a[2] == 1 # true
```
]
]
#slide(title: "OpenQASM features")[
  #cols(columns: (2fr, 1fr), gutter: 2em)[
  - Custom gate definitions & gate modifiers
  - Qubit arrays
  - Weird indexing behavior
    - You can index the bits of any number!
  - Splatting across qubit arguments
  - Combination of Pythonic and C-like semantics
][
```
qubit[4] q1;
qubit q2;
cx q1 q2;
```
]
]
#slide(title: "OpenQASM: 2 to 3")[
  - Now supports *control flow* such as `if`/`else`, `switch`
  - *Loops* are also supported
  - *Dynamic* circuits
  - *Function* definitions
  - Standard library of gates on top of builtin `U` and `gphase` gates
]

#slide(title: "OpenQasm example - " + `adder`)[

```
include "stdgates.inc";
gate majority a, b, c {
    cx c, b;
    cx c, a;
    ccx a, b, c;
}
gate unmaj a, b, c {
    ccx a, b, c;
    cx c, a;
    cx a, b;
}
qubit[1] cin;
qubit[4] a;
qubit[4] b;
qubit[1] cout;
```
]

#slide(title: "OpenQasm example - " + `adder`)[

```
bit[5] ans;
uint[4] a_in = 1;  // a = 0001
uint[4] b_in = 15; // b = 1111
// initialize qubits
reset cin;
reset a;
reset b;
reset cout;

// set input states
for uint i in [0: 3] {
  if(bool(a_in[i])) x a[i];
  if(bool(b_in[i])) x b[i];
}
```
]
#slide(title: "OpenQasm example - " + `adder`)[

```
// add a to b, storing result in b
majority cin[0], b[0], a[0];
for uint i in [0: 2] { majority a[i], b[i + 1], a[i + 1]; }
cx a[3], cout[0];
for uint i in [2: -1: 0] { unmaj a[i],b[i+1],a[i+1]; }
unmaj cin[0], b[0], a[0];
measure b[0:3] -> ans[0:3];
measure cout[0] -> ans[4];
```
]
#slide(title: "Introducing \"Quasar.jl\"?")[
  - *Qu*\antum *As*\sembly Language Pars#text(weight: "bold", "ar") (mangled a bit here for flair)
  - A Julia parser for OpenQASM 3
  - MIT licensed
  - Supports nearly all of OpenQasm 3 and parts of OpenPulse
  - Destination-agnostic output -- library developers can digest for their own custom objects
  - Available at #link("https://github.com/kshyatt-aws/quasar.jl")
  - Approximately 2000 lines of code total (excluding `test/`)
]

#slide(title: "One can write a parser in many languages. Why Julia, specifically?")[
  - Julia is a high performance, developer-friendly language for technical computing
  - The quantum sciences community in Julia is strong and growing
  - Julia community prefers not to have to call Python packages, especially "heavy" ones like `antlr`
  - Julia has nice tools to build upon for parsing a domain-specific language (DSL)
  - Good support for conditional code loading -- only load `C` if `A` and `B` are both present
  - Makes it easy to write plugins for many packages but keep things lightweight
]

#slide(title: "Backend tooling")[
  - `Quasar.jl` uses `Automa.jl` for tokenization.
  - `Automa.jl` is a regex-based tokenizer which is lightweight and quite performant
  - In fact, it is used in the Julia parser itself
  - Operates on the byte level which can be frustrating when working with Unicode
  - *Advantage*: don't have to pull in all of `antlr` and large number of recursive rules
  - *Disadvantage*: effectively have to re-implement those rules by hand
]

#slide(title: "QASM digestion in 3 simple steps")[
  1. Tokenization
  2. Parsing generated tokens to generate AST
  3. Walking AST to generate final list of instructions

  Developers can use all these or a subset depending on their needs
]

#slide(title: "From the user's point-of-view")[
```julia
using Quasar
qasm = """
       qubit[2] q;
       bit[2] c;

       h q[0];
       cz q[0], q[1];
       s q[0];
       cz q[0], q[1];
       measure q -> c;
       """
parsed  = parse_qasm(qasm)
visitor = QasmProgramVisitor()
visitor(parsed)
```
]

#slide(title: "Supplying custom gate sets")[
  - Developers supply a function to build a dictionary of gate name keys and gate definition values
  - Keys can be overwritten if a user wants to define their own version of (e.g.) `PauliX`
  - A built-in gate is a Julia `NamedTuple` with fields describing the gate's name, arguments, qubits, and modifiers
  - Allows quick construction of Julia `structs` using tools like `StructTypes.jl`
]

#slide(title: "Supplying custom gate sets: example")[
```julia
custom_builtin_gates() = 
Dict{String, Quasar.BuiltinGateDefinition}(
  "phaseshift"=>BuiltinGateDefinition("phaseshift",
                                      ["λ"],
                                      ["a"],
                                      (type="phaseshift",
                                       arguments=InstructionArgument[:λ],
                                       targets=[0],
                                       controls=Pair{Int,Int}[],
                                       exponent=1.0),
                                     ),
)
```
]

#slide(title: "Handling pragmas")[

  #table(
    columns: (auto, 1fr),
    stroke: none,
    [
      ```julia
      using Quasar
      function custom_pragma_parser(...)
        ...
      end
      function custom_pragma_visitor(...)
        ...
      end
      Quasar.parse_pragma[] = custom_pragma_parser
      Quasar.visit_pragma[] = custom_pragma_visitor
      parsed  = parse_qasm(qasm)
      visitor = QasmProgramVisitor()
      visitor(parsed)
      ```],
    [
      - Developers provide two custom functions:
        - One to parse their custom `#pragma`-s 
        - One to walk those parts of the AST
    ],
    )
]

#slide(title: "There are some package gotchas")[
  - Currently, visiting happens all in one go so mid-circuit measurement is not (yet) supported - obvious `TODO`
  - Incomplete support for OpenPulse (unsure what the dialect-agnostic output should look like)
  - Annotations not supported yet
  - Modular arithmetic for `angle` types needed
  - Dynamic circuit support, especially condtional execution based on mid-circuit measurement, still needed
]

#slide(title: "Reflections on OpenQASM itself")[
  - The spec is extremely Python-inflected (whether this is a pro or con is in the eye of the beholder)
  - Many qubit operations such as splatting are counterintuitive
  - Many of the OpenQASM documentation examples are broken
  - Why support so many Unicode characters for identifiers? Painful for byte-based tokenization due to Unicode internals
]

#slide(title: "Things could be much worse")[
  #grayed([_"We produce COBOL parsers, which have lexers for COBOL tokens feeding them. Our COBOL lexer (which handles 7 full dialects of COBOL) has 22,000 (YES!) lines of regex definitions of all the different tokens that all 7 COBOL dialects can produce."_])
  Source: #link("https://stackoverflow.com/questions/2842809/lexers-vs-parsers")

  The Julia language spec itself has lots of odd special cases and is quite nasty to parse correctly.
]

#slide(title: "Roadmap for the package")[
  - Full support for OpenQASM 3.x spec and OpenPulse
  - AST-walking should be "just in time" to allow for mid-circuit measurement and control flow
  - Proper support for `angle` types
  - Robust benchmarks to detect performance regressions
  - Integration with popular Julia packages
  - Improved documentation and examples

  #grayed([Suggestions?])
]
