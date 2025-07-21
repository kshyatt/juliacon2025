#import "@preview/typslides:1.2.3": *

#show: typslides.with(
  ratio: "16-9",
  theme: "greeny",
)

#front-slide(
  title: "What's new and improved in CUDA.jl?",
  //subtitle: [A Julia parser for OpenQASM 3],
  authors: "Katharine Hyatt",
  info: [#link("https://github.com/kshyatt")],
)

#slide(title: "Some high level impressions")[
  - Fewer big feature releases this year
  - Only 13 releases total since last year's JuliaCon
  - We've stayed at version `5.5.x` for nearly a year!
  - #stress[Does this mean `CUDA.jl` development is slowing down?]
]

// TODO image
#slide(title: "Test coverage is up!")[
  #align(center)[
   #image("coverage.png", width: 70% )
   #grayed[Coverage is up 16.2 % over the past year]
   Several bugs fixed, better library coverage, stale unreachable code removed!
   
   Most important: we went from *red* badge to *green* badge
 ]
]

#slide(title: "Using more functionality from " + `GPUArrays.jl`)[
  - Methods like `kron`, `axby`, and `dot` have backend-agnostic implementations in `GPUArrays.jl`
  - More flexibility for users, less device-specific code that is duplicated across repos
  - Plenty of opportunities here for new contributors -- the net negative lines PR is often welcome
]

#slide(title: "Broadcasting over sparse vectors")[
  - Now we can use broadcasting wtih `CuSparseVector`, not just the two main matrix types!
  - Broadcasting over a single dimension isn't yet supported for any sparse array type
  - Kernel for this isn't highly optimized, probably much more can be done here
]

// TODO code example
#slide(title: "Avoid synchronizations in CUBLAS")[
  - Some `CUBLAS` methods can return scalars or accept scalar inputs
  - If these scalars are in host memory, synchronization is forced for each method which severely affects performance
  - #stress[Good news!] `CUBLAS` wrappers now avoid this synchronization, while still providing convenience methods so you don't have to change your code
]

#slide(title: "Many small QOL improvements")[
  - Large number of improvements to the underlying GPU compiler
  - Moving wrappers from older library methods to new ones
  - Enabling use of more types (e.g. `Float16`)
  - Some of these are hard to notice, but the improvements pile up!
]

#slide(title: "Where should we focus development in the upcoming year?")[
  - More features?
  - More low level compiler improvements?
  - More generic implementations to make our code more portable?
  - We'll discuss in the panel!
]
//#table-of-contents()

