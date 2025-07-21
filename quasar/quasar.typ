#import "@preview/typslides:1.2.3": *

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

#slide(title: "What is \"Quasar.jl\"?")[
  - *Qu*\antum *As*\sembly Language Pars#text(weight: "bold", "ar") (mangled a bit here for flair)
  - A Julia parser for OpenQASM 3
  - MIT licensed
  - Supports nearly all of OQ3 and parts of OpenPulse
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

#slide(title: "Quantum Julia")[
  - There's a growing community of Julia QI packages
    - `Yao.jl`
    - `KestrelQuantum`
    - `QuantumToolbox.jl`
    - `ITensor.jl`
    - `MPSKit.jl`
  - Two separate quantum tracks this year at JuliaCon
  - Many Julia users in the quantum community are researchers (postdocs, staff scientists, PIs)
]

#slide(title: "What are the downsides of using Julia?")[
  - Not as prevalent as Python
  - "Time to first X" due to JIT compilation - this has improved a lot and still getting better
  - Library ecosystem not yet mature
  - SDE hostility
]

#slide(title: "Backend tooling")[
  - `Quasar.jl` uses `Automa.jl` for tokenization.
  - `Automa.jl` is a regex-based tokenizer which is lightweight and quite performant
  - In fact, it is used in the Julia parser itself
  - Operates on the byte level which can be frustrating when working with Unicode
  - *Advantage*: don't have to pull in all of `antlr` and large number of recursve rules
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
  - Full support for OpenQASM 3 spec and OpenPulse
  - AST-walking should be "just in time" to allow for mid-circuit measurement and control flow
  - Proper support for `angle` types
  - Robust benchmarks to detect performance regressions
  - Integration with popular Julia packages
  - Improved documentation and examples

  #grayed([Suggestions?])
]
