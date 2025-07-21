#import "@preview/typslides:1.2.5": *

#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
)

#front-slide(
  title: "Lead, follow, or get out of the way",
  subtitle: [Julia and threaded Python],
  authors: "Katharine Hyatt",
  info: [#link("https://github.com/kshyatt")],
)

#slide(title: "There's demand for Python interfaces on top of Julia code")[
  - Many end users prefer to stick with what they know
  - Python interfaces make it easy for other Python code (e.g. `scipy`) to call Julia seamlessly
  - Allows speeding up "hot" part of code without having to replace entire codebase
  - Python is highly entrenched in industry and (some areas of) science and not going away anytime soon
]

#slide(title: "Calling Julia from Python introduces new complications")[
  - How do the two languages share memory objects?
  - Both Julia and Python are garbage collected -- whose GC runs when? What if both languages are mutating the same memory object?
  - Can each Python thread call into the same Julia process?
  - How does precompilation work (or not)?
]

#slide(title: "The Global Interpreter Lock")[
  - The GIL enforces that *only one* thread can be executing an instruction *per Python process*
  - In effect, Python threads are "fake"
  - They are still useful for asynchronous operations like
    - waiting for a download
    - waiting for a C library to do something
]

#slide(title: "Why is the GIL such a problem?")[
  - Only one Python thread per process can be executing an instruction
  - The GIL *can* be released when calling into other languages, *if* we can guarantee not to touch Python memory
  - Using processes is awful!
  - Or you can write Cython and call into that which is also awful 
]

#slide(title: `juliacall` + " has nice support for working with Julia threads")[
  - Simple interface for releasing and reacquiring the GIL
  - Handles initializing Julia for you at module import
  - Annoying that package deps are only installed at first import
  - Can call Julia functions with `._jl_call_nogil` suffix to... avoid the GIL
  - *Any* call with this suffix *must not* interact with Python at all without relocking the GIL
]

#slide(title: "But " + `juliacall` + " can't protect us from everything")[
  - What if you *want* to interact with Python?
  - `juliacall` can't do much if the initial Julia startup enters a deadlock
  - You have to yield back into the Julia scheduler to allow tasks to run -- if you're not yielding early or often enough, things will hang
  - How do you know where and how much to yield?
]

#slide(title: `ThreadPoolExecutor` + " and its many \"features\"")[
  - Our Julia process may be launched off a *non-main* Python thread, created by a Python `ThreadPoolExecutor`
  - Even worse, we may not have any control of how that thread is initialized!
  - This means we cannot guarantee that the needed `juliacall` functions are called when the thread starts, potentially causing a lock
  - Python libraries may use `ThreadPoolExecutor` to launch workers, and short of making PRs to every Python library on Earth, we can't stop them
]

#slide(title: "Python processes vs threads")[
  #cols(columns: (1fr, 1fr), gutter: 2em)[Processes
  - Each process has its own GIL
  - Multiple processes can be active at once
  - Processes (mostly) *don't* share memory][Threads
   - Subject to parent process' GIL
   - Only one can be active at once
   - Memory objects are shared among threads]
]

#slide(title: "Isn't the risk just slower performance?")[
  #align(center)[
  Unfortunately, *no*.

  The entire process can enter a deadlock as

  threads all wait for each other to release the GIL.]
]

#slide(title: "One possible solution")[
  // TODO diagram
  - Manage threaded Julia code in a separate *process*, which is interacted with from the main Python wrapper thread
  - Can be done with `ProcessPoolExecutor` or `multiprocessing.Pool`
  - Works *even if* we are launched by a non-main Python thread
]

#slide(title: "One possible solution ... and its downsides")[
  - Have to initialize the process pool at module initialization (data race risk?)
  - Hard to share memory with the Julia worker process (more later)
  - The Python `multiprocessing.Pool` interface isn't nice
  - What if multiple Python threads want to use the Python wrapper module?
    - Do we create a new process for each?
    - Or share the Julia manager between them?
]

// TODO code slides
#slide(title: "What does this look like in practice?")[

]

#slide(title: "Sharing memory among Python processes")[
  - Python's `multiprocessing` does allow processes to return arrays -- as long as they can be `pickle`-d
  - Problematic if we have custom structs that `pickle` isn't sure how to handle
  - This inter-process communication can have *high overhead*
  - Pickling large arrays and returning the resulting object is *slow*
]

#slide(title: `pickle` + " can be very slow")[

  #cols(columns: (2fr, 1fr), gutter: 2em)[
  Some strategies to get around this:
  - #emoji.face.halo Just don't move large arrays
  - #emoji.page.pencil Memory map large objects to disk
  - #emoji.mirror Copy-on-write (has restrictions)
][ #image("qr_code.png")

Nice blog post about this issue
]
]

#slide(title: "Passing memory back and forth: example")[
  ```julia

  ```
]

#slide(title: "The Global Interpreter Lock ... is going away!")[
  #cols(columns: (2fr, 1fr), gutter: 2em)[
  
    #image("no_gil.png")
  ][
    #image("qr_code_gil.png")
  ]
]


#slide(title: "Future of the GIL in Python")[
  - Recent (>= 3.13) Python versions experimentally support a GIL-free paradigm!
  - But library maintainers need to modify their code to work with it
  - Most Python developers aren't used to dealing with "free threading" 
  - Big packages like `numpy` and `scipy` have the support/clout to do this, smaller ones may not
  - Free-threaded Python has worse (40%) performance in some cases #emoji.face.fear
  #stress[The GIL will be with us for a long time yet]
]

#slide(title: "In sum")[
  - While the GIL is still present "in the wild," we need a way to work around it
  - Using a separate Julia-controller process is one possible solution
  - Is it a *good* solution? There's no accounting for taste...


  #grayed[Questions?]
]
//#table-of-contents()


