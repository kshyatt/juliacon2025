### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 39d60cf2-657b-11f0-2ba8-f7f43e53295d
md"
# Introduction to quantum theory (in ten minutes or less!)

In this session we'll go over some of the basics of quantum theory to set the stage for our introduction to classical simulation of quantum systems and quantum computation. In particular, we will cover:

- A brief review of classical probability to motivate the changes we need to understand quantum systems
- Some hands-on exercises to explore how we represent quantum objects on classical hardware
- Discuss why we might care about this from a computer science or high-performance computing point of view
"

# ╔═╡ 12c20e3f-57c1-4cfa-9763-b14b17b30eea
md"""
## Generalizing from classical probability theory

Suppose we have some classical system that can be in one of a finite number of possible states, and of course there has to be more than zero such possible states. Let's restrict our discussion to the possible states $\{0, 1\}$ (the good old classical bits we love so well). 

Let's also suppose that we're, for example, flipping a coin to figure out whether the coin is biased or not. After doing a bunch of coin flips, we think the coin has a $\frac{5}{6}$ chance to come up tails (0) and a $\frac{1}{6}$ chance to come up heads (1) -- pretty biased. We could represent this as:

```math
\begin{align*}
\mathtt{Pr}(0) =& \frac{5}{6} \\
\mathtt{Pr}(1) =& \frac{1}{6} \\
\end{align*}
```

Or, we could write it more compactly as a vector:

```math
\vec{p} = \begin{bmatrix} \frac{5}{6} \\ \frac{1}{6} \end{bmatrix}
```

Where we put the tails (0) state on top. For any complete set of states like this, we require that
- All the probabilities are real numbers $\geq 0$
- The probabilities all sum to $1$

### Making measurements

We can write the two possible states as $|0\rangle$ (tails) and $|1\rangle$ (heads). These have vector forms 

```math
\begin{align*}
|0\rangle =& \begin{bmatrix} 1 \\ 0 \end{bmatrix} \\
|1\rangle =& \begin{bmatrix} 0 \\ 1 \end{bmatrix} \\
\end{align*}
```
These $|0\rangle$ and $|1\rangle$ representations are called \"ket\"s and they are part of [Dirac notation](https://en.wikipedia.org/wiki/Bra%E2%80%93ket_notation). Why we include the $|...\rangle$ will be clear soon!

So we could also write the probability expression for the biased coin as:

```math
|p\rangle = \frac{5}{6} | 0 \rangle + \frac{1}{6}|1\rangle
```

So that the probability vector describing the coin's bias is a linear combination of the two possible outcome states -- tails and heads.

Now we want to flip the coin and see what outcome we can expect. To do this, we'll introduce the \"bra\" side -- written $\langle ... |$. This is the *dual* of the ket, and we can write it as a row vector:

```math
\begin{align*}
\langle 0 | =& \begin{bmatrix} 1 & 0 \end{bmatrix} \\
\langle 1 | =& \begin{bmatrix} 0 & 1 \end{bmatrix} \\
\end{align*}
```

If we multiply a bra on the left into a ket on the right, we get a scalar:

```math
\begin{align*}
\langle a | a \rangle =& 1 \\
\langle a | b \rangle =& 0; ( a \neq b ) \\
\end{align*}
```

Which makes sense as these are orthonormal basis elements.

We can also take an outer product by reversing the order:

```math
\begin{align*}
| 0 \rangle \langle 0 | =& \begin{bmatrix} 1 \\ 0 \end{bmatrix} \otimes \begin{bmatrix} 1 & 0 \end{bmatrix} \\
=& \begin{bmatrix} 1 & 0 \\ 0 & 0 \end{bmatrix} \\
| 0 \rangle \langle 1 | =& \begin{bmatrix} 1 \\ 0 \end{bmatrix} \otimes \begin{bmatrix} 0 & 1 \end{bmatrix} \\
=& \begin{bmatrix} 0 & 1 \\ 0 & 0 \end{bmatrix} \\
| 1 \rangle \langle 0 | =& \begin{bmatrix} 0 \\ 1 \end{bmatrix} \otimes \begin{bmatrix} 1 & 0 \end{bmatrix} \\
=& \begin{bmatrix} 0 & 0 \\ 1 & 0 \end{bmatrix} \\
| 1 \rangle \langle 1 | =& \begin{bmatrix} 0 \\ 1 \end{bmatrix} \otimes \begin{bmatrix} 0 & 1 \end{bmatrix} \\
=& \begin{bmatrix} 0 & 0 \\ 0 & 1 \end{bmatrix} \\
\end{align*}
```

If we flip the coin, we have a $\frac{5}{6}$ chance for it to come up tails. Let's say we do flip it and it comes up heads -- before we looked at the result, there was a $\frac{1}{6}$ chance of heads, but now **for that flip**, the chance of heads is 1 (because we know the result and have eliminated tails). To model this process we could make a weighted sample from the distribution of classical heads/tails probabilities, then record the result of the `n`-th flip. The probability of observing a certain state, say $|1\rangle$, is $\langle 1 | p \rangle$. 
"""

# ╔═╡ 71aad128-9a37-46d4-92ea-e676a24f3e82
md"
## Exercise

Let's try making some coin flips! For `n = 100` flips, generate a random number and use it to pick whether the very biased coin would return tails or heads.
"

# ╔═╡ 098627e8-bb24-4380-86af-dd3549811751
for n = 1:100

end

# ╔═╡ 7796c3ac-da92-4153-9d7c-93c572bf8d30
md"
### Quantum analogy to the classical probability vector

In the quantum case, we will work with **state vectors**, which are **complex** (not necessarily real!) vectors of **probability amplitudes**. These amplitudes squared recover the normal positive real valued probabilities. The statevector represents the \"wavefunction\" (quantum people have a lot of different names for things) of the system, its probability distribution across possible states. We usually write a generic state vector as $|\psi\rangle$.

Statevectors:
- Have complex valued elements
- Are normalized, so that $\sum_i| \psi_i |^2 = 1$

To find the probability of observing the tails of a **quantum** coin, we would compute $|\langle 0 | \psi \rangle|^2$.

This is enough to capture the special features of quantum systems, like entanglement and global phase.

**Note**: for quantum state vectors, the \"bra\" is the **complex conjugate**, so that
```math
\bra \psi  = (|\psi\rangle)^\dagger
```
"

# ╔═╡ b96bcce9-4c48-4aeb-a7b9-e3f5668644f2
md"

# Exercise

Let's pretend we have a *quantum* coin with state vector

```math
|\psi\rangle = \frac{1}{\sqrt{2}} \times \begin{bmatrix} 1 \\ -i \end{bmatrix}
```

Is $|\psi\rangle$ normalized? Can you check numerically?

How would you replicate the `n = 100` flips from above?
"

# ╔═╡ 8a1c9156-a301-4d9b-9fbe-70bfeaf4a5cf
for n = 1:100
	
end

# ╔═╡ d0fe352c-7aca-40ee-8648-abff315aa04d
md"
## Another orthonormal basis

We already looked at the basis $\ket{0}$ and $\ket{1}$. We can transform this to a new orthonormal basis 
```math
\begin{align*}
\ket{+} =& \frac{1}{\sqrt{2}} \ket{0} + \frac{1}{\sqrt{2}}\ket{1} \\
\ket{-} =& \frac{1}{\sqrt{2}} \ket{0} - \frac{1}{\sqrt{2}}\ket{1} \\
\end{align*}
```
"

# ╔═╡ 68b4479b-b36a-45f2-9612-f1dae60d5ded
md"
## Exercise

Verify that the $\ket{+}$ and $\ket{-}$ states form an orthonormal basis. How would you write these as vectors?
"

# ╔═╡ d02fd246-b7a6-416e-8ff2-a74a05809b78


# ╔═╡ 1c03d3af-1427-4b8d-9101-954e2dd040c0
md"
What's the point of this? Just as in the linear algebra we know, change of basis can often make a problem more tractable. Additionally, it reminds us that it's common to use the symbol inside the \"ket\" as a label, and it may in the end describe a very complex continuous function! (This is common in atomic physics, for example). But the notation is general enough to be applied to a lot of quantum systems.
"

# ╔═╡ 16ac526d-f7ad-4c5c-b9da-049bf87541eb
md"

## Density matrices

A state vector represents what we call a \"pure state\". For such a state, we have full information about the probability distribution across the outcomes and the state is isolated from its environment. However, in the real world, it's often the case that a quantum system interacts with its environment and the perfect picture about its state becomes \"smudged\". We can represent one of these **mixed states** with a **density matrix**, traditionally written $\rho$.

A density matrix has the following form:

```math
\rho = \rho_ij \ket{i}\bra{j}
```

So for a single-particle state:

```math
\begin{align*}
\rho_1 =& \begin{bmatrix} \rho_{00} & \rho_{01} \\ \rho_{10} & \rho_{11} \end{bmatrix} \\
=& \rho_{00}\ket{0}\bra{0} + \rho_{01}\ket{0}\bra{1} + \rho_{10}\ket{1}\bra{0} + \rho_{11}\ket{1}\bra{1}\\
\end{align*}
```

The diagonal of $\rho$ contains the normed probabilities of measuring each state, **not** the probability amplitudes (as in a state vector). The diagonal is real-valued and all elements must be $\geq 0$ and sum to $1$, so the trace of $\rho$ is **always** $1$.

A pure state's density matrix can be constructed from its state vector $\ket\psi$ by performing the operation

```math
\rho = \ket{\psi}\bra{\psi}
```

Any density matrix that can be written in this form, as the outer product of a **single** state vector, is pure. This leads to some useful properties:

```math
\begin{align*}
\rho_{p} =& \ket{\psi}\bra{\psi} \\
\rho^2_p =& (\ket{\psi}\bra{\psi}) (\ket{\psi}\bra{psi}) \\
=& \ket{\psi} \braket{\psi | \psi} \bra{\psi} \\
=& \ket{\psi}\bra{\psi} \\
\end{align*}
```
If the trace of $\rho^2$ is one, then a state is pure. If not, it's mixed. Mixed states are written as a linear combination of other density matrices, like:

```math
\rho_m = \frac{1}{2} \ket{0}\bra{0} + \frac{1}{2}\ket{1}\bra{1}
```
"

# ╔═╡ 34cac984-761b-45de-a618-29b13039005f
md"
## Exercises

Let's look at some density matrices and determine if they represent pure or mixed states.
"

# ╔═╡ fe171d54-a342-4d7c-9c6d-db2e408435b0
ρ_1 = (1/4) * [1 1; 1 3]

# ╔═╡ 2996b88e-7a02-4c9d-8527-18205d7e7f5a


# ╔═╡ 0013b38a-a088-40ae-b998-d6b9a825dc0e
ρ_2 = (1/2) * [1 0; 0 1]

# ╔═╡ ef9b4112-b1e2-40e3-82bb-83d41b2f344e


# ╔═╡ eec874b2-0532-469d-9689-24ca2ff44386
ρ_3 = 0.1 * kron([1/√2 1/√2], [1/√2, 1/√2]) + 0.9 * kron([1/√2 im/√2], [1/√2, -im/√2])

# ╔═╡ 93628d61-0ac8-48a9-b42e-f7ac76f8d397


# ╔═╡ 93c4997d-dbbd-497f-8d2a-355f7821c21a
md"

## Why should we care about any of this if we're not physicists or chemists?

For some problems, exploiting the laws of quantum mechanics in a *fault tolerant* (error corrected) way would allow us to find a solution with polynomial or even exponential speedup. Many of these problems are of large societal or industrial importance, like materials design or scheduling for logistics. This is why quantum computation has attracted a large amount of private and public investment, of course. But the fault-tolerant days are probably a ways off, and in the meantime we can still improve our *classical* algorithms and techniques by benchmarking and comparing them against what quantum hardware can do. For quantum computing to be worthwhile for actual applications, it needs to outperform the classical state of the art, which is a moving and ever-improving target, though of course there are fundamental bounds on the efficiency of simulation of quantum systems with classical hardware. But for now, clever classical algorithm development allows classical resources to outperform today's noisy, small quantum devices. These techniques can be used in other applications as well, where we don't necessarily anticipate a massive speedup from a future fault-tolerant quantum computer.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.6"
manifest_format = "2.0"
project_hash = "da39a3ee5e6b4b0d3255bfef95601890afd80709"

[deps]
"""

# ╔═╡ Cell order:
# ╟─39d60cf2-657b-11f0-2ba8-f7f43e53295d
# ╟─12c20e3f-57c1-4cfa-9763-b14b17b30eea
# ╟─71aad128-9a37-46d4-92ea-e676a24f3e82
# ╠═098627e8-bb24-4380-86af-dd3549811751
# ╟─7796c3ac-da92-4153-9d7c-93c572bf8d30
# ╟─b96bcce9-4c48-4aeb-a7b9-e3f5668644f2
# ╠═8a1c9156-a301-4d9b-9fbe-70bfeaf4a5cf
# ╟─d0fe352c-7aca-40ee-8648-abff315aa04d
# ╟─68b4479b-b36a-45f2-9612-f1dae60d5ded
# ╠═d02fd246-b7a6-416e-8ff2-a74a05809b78
# ╟─1c03d3af-1427-4b8d-9101-954e2dd040c0
# ╟─16ac526d-f7ad-4c5c-b9da-049bf87541eb
# ╟─34cac984-761b-45de-a618-29b13039005f
# ╠═fe171d54-a342-4d7c-9c6d-db2e408435b0
# ╠═2996b88e-7a02-4c9d-8527-18205d7e7f5a
# ╠═0013b38a-a088-40ae-b998-d6b9a825dc0e
# ╠═ef9b4112-b1e2-40e3-82bb-83d41b2f344e
# ╠═eec874b2-0532-469d-9689-24ca2ff44386
# ╠═93628d61-0ac8-48a9-b42e-f7ac76f8d397
# ╟─93c4997d-dbbd-497f-8d2a-355f7821c21a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
