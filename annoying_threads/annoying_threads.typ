#import "@preview/typslides:1.2.5": *

#show: typslides.with(
  ratio: "16-9",
  theme: "reddy",
)

#front-slide(
  title: "Things that annoyed me about multithreading in 2024",
  //subtitle: [A Julia parser for OpenQASM 3],
  authors: "Katharine Hyatt",
  info: [#link("https://github.com/kshyatt")],
  // TODO ADD PICTURE OF ICE CREAM SANDWICH
)

#slide(title: "First, good things about Julia threads")[
  - Dynamic threading and task migration mostly "just work"
  - Really nice support for atomics
  - Interaction with `Channel`s promotes good design
  - Don't have to use macros to do everything
  - We've had "good enough" coarse-graining for a while!
]

#focus-slide[But there are some pain points]

#slide(title: "Schedule thrashing")[
  - A lot of CPU cores (96) + a LOT of short-lived `Task`s = slowdown in the scheduler
    - But isn't this really a coder error?
  - Easy to write naive code that experiences this anti-pattern
  - Can be hard to detect when testing on a laptop
  - Has improved with the naive coarse graining in the scheduler
  - But `Task` overhead is still frustrating...
]

#let partition_block = raw("
  INNER_SIZE  = a
  MIDDLE_SIZE = b
  OUTER_SIZE  = c
  for out_ix in 1:OUTER_SIZE
    do_outer_work()
    for mid_ix in 1:MIDDLE_SIZE
      do_middle_work()
      for in_ix in 1:INNER_SIZE
        do_inner_work()
      end
    end
  end
", lang: "julia")
#slide(title: "Figuring out which loop to thread is annoying")[
  Consider this work pattern
  #cols(columns: (1fr, 1fr), gutter: 2em)[
    #partition_block
  ][
    If `a`, `b`, and `c` are all small, we can just stick a `Threads.@threads` in front of each `for`.
  ]
]

#slide(title: "Figuring out which loop to thread is annoying")[
  #cols(columns: (1fr, 1fr), gutter: 2em)[
    #partition_block
  ][
  if `a`, `b`, and `c` are *not* known at compile time and may not be small, so that `a*b*c` is large, where to put `Threads.@threads`?
]
]

#slide(title: "How to use threads most effectively in this situation?")[
  - We could dispatch to different functions depending on which of `INNER_SIZE`, `MID_SIZE`, `OUTER_SIZE` is largest
  - We could try to collapse everything into one loop and "back compute" the inner, middle, and outer indices
  - Would be great if the threading scheduler could figure this out semi-intelligently *or* if I could specify a `max_threads` for a (nested) threaded block 
]

#slide(title: "The closing " + `end` + " is missed by coverage")[
  // TODO SCREENCAP OF COVERAGE
  - This may be more of a coverage system problem but I encounter it when using `Threads`
  - It messes with my beautiful 100% coverage statistics for files
]

#slide(title: `Threads.@threads for` + "has a lot of sharp edges")[
  ```julia
  Threads.@threads for ix = 1:N, j = 1:M
    ...
  end
  ```
  #stress[BANNED!] This doesn't work.
  ```julia
  ERROR: LoadError: ArgumentError: nested outer loops are not currently supported by @threads
  Stacktrace:
  [1] var"@threads"(__source__::LineNumberNode, __module__::Module, args::Vararg{Any})
   @ Base.Threads ./threadingconstructs.jl:404
  ```
]

#slide(title: "Things are getting better!")[
  - Scheduler slowdowns have improved (see Gabriel's talk!)
  - We have an ecosystem of threading packages with friendly cooperation/competition
  - Good ideas can be taken from these other packages and incorporated into base's `Threads`
]

