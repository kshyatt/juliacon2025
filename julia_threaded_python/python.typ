#import "@preview/typslides:1.2.5": *
#import "@preview/cetz:0.4.1"

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
  #cols(columns: (1fr, 1fr), gutter: 2em)[
  - What if you *want* to interact with Python?
  - `juliacall` can't do much if the initial Julia startup enters a deadlock
  - We *must* yield back into the Julia scheduler to allow tasks to run -- if we are not yielding early or often enough, Julia threads *will* hang
  - How do you know where and how much to yield?][
  #image("juliacall_docs.png")
]
]

#slide(title: `juliacall` + " may be imported on a non-main thread")[
  - 3rd party libraries may launch the Julia package's wrapper in ways we can't control
  - Example scenario: `SomePythonLibrary` creates a `ThreadPoolExecutor` which will manage workers which use the Julia code
  - When the `ThreadPoolExecutor` is created, an initializer function `initializer` and arguments to it can be provided
  ```python
  ThreadPoolExecutor(max_workers=None, thread_name_prefix='', initializer=None, initargs=())
  ```
  - `initializer` is run with its `init_args` at the startup of each worker thread
  - #stress[How do you (politely) ask every 3rd party library to initialize its threads with a yield to the Julia scheduler?] 
]


#slide(title: "Stuck waiting for a " + `yield`)[
  - Julia internal functions during startup may yield into the task scheduler!
  - Experimentally, the "stuck waiting to `yield()`" problem seems to occur when `juliacall` is not run on the main Python thread
  - #stress[Why???] Python experts are welcome to answer this!
  - Processes, which differ from threads in important ways, can help.
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
  #cols(columns: (1fr, 1fr), gutter: 2em)[
  #cetz.canvas({
  import cetz.draw: *
  rect((0, 10), (6, 4), fill: aqua)
  content((0, 10.75), (6, 10.75), auto_scale: true, "Python process")
  
  rect((0.5, 6), (1.5, 7), fill: olive)
  rect((2, 6), (3, 7), fill: olive)
  rect((3.5, 6), (4.5, 7), fill: olive)
  
  rect((0.5, 7.5), (1.5, 8.5), fill: olive)
  rect((2, 7.5), (3, 8.5), fill: olive)
  rect((3.5, 7.5), (4.5, 8.5), fill: olive)
  
  rect((0.5, 4.5), (5.5, 5.5), fill: maroon)
  content((1, 4.75), (5.5, 5.25), auto_scale: true, text(fill: white)[Julia process])
  })
  ][
  #cetz.canvas({
  import cetz.draw: *
  rect((0, 4), (6, 10), fill: aqua)
  content((0, 10.75), (6, 10.75), auto_scale: true, "Python process")
  
  rect((0.5, 6), (1.5, 7), fill: olive)
  rect((2, 6), (3, 7), fill: olive)
  rect((3.5, 6), (4.5, 7), fill: olive)
  
  rect((0.5, 7.5), (1.5, 8.5), fill: olive)
  rect((2, 7.5), (3, 8.5), fill: olive)
  rect((3.5, 7.5), (4.5, 8.5), fill: olive)
  
  line((6, 7), (7,7), mark: (start: "stealth", end: "stealth")) 
  
  rect((7, 4), (13, 10), fill: aqua)
  content((7, 10.75), (13, 10.75), auto_scale: true, "Python process")
  rect((7.5, 4.5), (12.5, 9.5), fill: maroon)
  content((8, 7.5), (12.5, 7.5), auto_scale: true, text(fill: white)[Julia process])
  })
  ]
  - Manage threaded Julia code in a separate *process*, which is interacted with from the main Python wrapper thread
  - Can be done with `ProcessPoolExecutor` or `multiprocessing.Pool`
  - Works *even if* the wrapper module is imported by a non-main Python thread
]

#slide(title: "One possible solution ... and its downsides")[
  - Have to initialize the process pool at module initialization (data race risk?)
  - Hard to share memory with the Julia worker process (more later)
  - The Python `multiprocessing.Pool` interface isn't nice
  - What if multiple Python threads want to use the Python wrapper module?
    - Do we create a new process for each?
    - Or share the Julia manager between them?
]

#slide(title: "What does this look like in practice? -- Creating the worker")[
```python
from multiprocessing.pool import Pool
__JULIA_POOL__ = None

def setup_pool():
    # We use a multiprocessing Pool with one worker
    # in order to bypass the Python GIL. This protects us
    # when the simulator is used from a non-main thread from another
    # Python module. However it involves a global, probably horrible...
    global __JULIA_POOL__
    __JULIA_POOL__ = Pool(processes=1)
    __JULIA_POOL__.apply(setup_julia)
    atexit.register(__JULIA_POOL__.join)
    atexit.register(__JULIA_POOL__.close)
    return
```
]

#slide(title: "What does this look like in practice? -- Setting up Julia")[
#show raw: set text(size: 14pt)
```python
def setup_julia():
    import os
    import sys

    # don't reimport if we don't have to
    if "juliacall" in sys.modules and hasattr(sys.modules["juliacall"], "Main"):
        os.environ["PYTHON_JULIACALL_HANDLE_SIGNALS"] = "yes"
        return
    else:
        for k, default in (
            ("PYTHON_JULIACALL_HANDLE_SIGNALS", "yes"),
            ("PYTHON_JULIACALL_THREADS", "auto"),
            ("PYTHON_JULIACALL_OPTLEVEL", "3"),
            # let the user's Conda/Pip handle installing things
            ("JULIA_CONDAPKG_BACKEND", "Null"),
        ):
            os.environ[k] = os.environ.get(k, default)

        from juliacall import Main as jl # import Julia packages into Main below
```
]

#slide(title: "What does this look like in practice? -- Doing useful work")[
```python
# can run on any Python thread
def some_task_runner(*args):
    global __JULIA_POOL__
    try:
        jl_result = __JULIA_POOL__.apply(julia_interface_runner, args)
    except Exception as e:
        # translates/unwraps JuliaCall error types to Python 
        _handle_julia_error(e)
    # more python result processing occurs here!
```
]

#slide(title: "What does this look like in practice? -- Doing useful work")[
```python
# runs on the jointly owned process 
def julia_interface_runner(*args):
    jl = getattr(sys.modules["juliacall"], "Main")
    return jl.MyJuliaPackage.run_stuff(args)
```
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

#slide(title: "Passing memory back and forth: the Julia side")[
#show raw: set text(size: 14pt)
```julia
const MUST_MMAP = 2^20
function _mmap_large_result_values(results)
    to_mmap     = findall(rt->sizeof(rt) > MUST_MMAP, results)
    isempty(to_mmap) && return nothing, nothing
    paths_and_lengths = map(to_mmap) do r_ix
        tmp_path, io = mktemp()
        write(io, results[r_ix])
        result_size = length(results[r_ix])
        empty!(results[r_ix]) # avoid copying back with pickle
        close(io)
        return (tmp_path, result_size)
    end
    py_paths    = tuple((x->x[1] for x in paths_and_lengths)...)
    py_lens     = tuple((x->x[2] for x in paths_and_lengths)...)
    return py_paths, py_lens
end
```
]

#slide(title: "Passing memory back and forth: the Python side")[
```python
def _handle_mmaped_result(result, mmap_paths, obj_lengths):
    if mmap_paths:
        mmap_index = 0
        for result_ind, result_obj in enumerate(result):
            if not result_obj:
                d_type = # some logic here! 
                result[result_ind] = np.memmap(
                    mmap_paths[mmap_index],
                    dtype=d_type,
                    mode="r",
                    shape=(obj_lengths[mmap_index],),
                )
                mmap_index += 1
    return result
```
]

#focus-slide[But this is just so horrible! I hate it!]

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


