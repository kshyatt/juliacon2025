### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 835e5f0f-44a7-4b47-b439-802224b6f915
using LinearAlgebra

# ╔═╡ 4c5756b5-4dad-4c77-8266-df8c5b313604
using Chairmarks

# ╔═╡ ee5e6301-817b-40e7-930f-4c436d2d0a7b
using AliasTables

# ╔═╡ b3c619ca-657c-11f0-31b8-7db9d45d291d
md"
# Simulating quantum systems on a classical computer

![](https://github.com/kshyatt/juliacon2025/blob/main/workshop/always_has_been.jpg)

We now want to take an in-depth look at how we can represent & simulate an ensemble of quantum objects on a classical computer. For simplicity, we'll work with so-called *two level systems* -- these are quantum systems in which the individual objects in the ensemble have two possible states, which for convenience we'll write as $|0\rangle$ and $|1\rangle$. You can probably see why this is a reasonable restriction to make, and why it simplifies our lives as classical programmers, although in reality nature isn't so simple. In fact, a lot of work goes into finding real-world systems that we can use as successful models of two-level systems, and a huge amount of the problem of building real-world quantum computers involves preventing the hardware from \"leaking\" into other accessible states besides the ones we've designated $|0\rangle$ and $|1\rangle$. All this is to say that the real world is more complex than the somewhat cartoonish picture we'll paint here.
"

# ╔═╡ 9ae17620-14a3-4578-ad60-0ea60665c6eb
md"
## What actually are these $|0\rangle$ and $|1\rangle$ states?

Any physical system governed by the laws of quantum mechanics has a **discrete** (or *quantized*) set of possible states that its constituent particles can occupy. A common example is the orbitals of the hydrogen atom, pictured below:

![](https://upload.wikimedia.org/wikipedia/commons/c/cf/HAtomOrbitals.png)

The single electron of a hydrogen atom can occupy any of these orbitals, but they are all orthonormal to one another and have different energies associated with each.

These quantum states form an orthonormal basis of some vector space. Then, we can remind ourselves that linear operators act on vector spaces to map vectors from one to another. In the physical world, various physical interactions can move a quantum object from one of these states to another, driving transitions from $|0\rangle \to |1\rangle$ or vice-versa (an example of this would be a particle absorbing then emitting a photon). We can represent these interactions as *linear operators*, which map $\mathbb{C}^2 \to \mathbb{C}^2$. Additionally, there are a few other conditions:

- These operators must be *norm-preserving*, that is, any vector operated upon by such an operator has its 2-norm preserved
- These operators are *unitary* (connected to the above), so that for some operator $U$, $U \times U^\dagger = \mathbb{I}$.

We can model the interaction of a \"closed\" quantum system, the wavefunction of which maintains a total probability of 1, as a series of linear operators applied to the wavefunction representation -- either a statevector or density matrix.

```math
|\phi\rangle = U |\psi\rangle
```

We could recover the state $|\psi\rangle$ by applying the inverse of $U$, its adjoint:

```math
|\psi\rangle = U^\dagger |\phi\rangle
```

So any process of applying unitary operators is *reversible*.

In the particular case of quantum computation, we can represent the logical operations we want to use to perform some algorithm as unitary operators a.k.a. gates, as we'll see later.


"

# ╔═╡ 50fd912f-72cf-47da-ac9d-8144f1c64bc0
md"
## \"Observables\" and expectation values

In a physical system, we need a way to make **measurements**, which collapse the wavefunction into one of its possible outcome states. Usually measurements are made with respect to some *observable* $O$, which is a *Hermitian* linear operator and is **not** necessarily norm-preserving. To make this a little more concrete, if we make a measurement with respect to the $Z$ operator, we're \"asking\" whether the system is \"up\" ($|0\rangle$) or \"down\" ($|1\rangle$) in the $z$-direction.

We represent this process mathematically with an inner product of the form

```math
\begin{align*}
\mathtt{expval}(O) &= \mathtt{dot}(\psi, O, \psi) \\
\langle O \rangle &= \langle \psi | O | \psi \rangle \\
\end{align*}
```

The $\langle O \rangle$ is a shorthand for \"expectation value of $O$\". The $\langle \psi |$ is the *dual* of $|\psi\rangle$, in this case its adjoint.

A measurement is **irreversible** -- once it's been done, the information about the states that were not observed is lost.

When we take an expectation value with the full statevector, we're computing the average that we would measure if we set up an experiment and ran it an infinite number of times under the same conditions. Effectively, we're computing what the mean observation in the lab should be given sufficient trials, using our idealized representation of the system.
"

# ╔═╡ 0e75d215-358a-4871-aeb7-43f2ec78eed9
md"
## Exercises

Now we'll examine how to implement some of this on classical computers. First, we need a way to represent the state vector. The fact that our two states are called $|0\rangle$ and $|1\rangle$ is pretty suggestive -- we can write an arbitrary statevector for a single 2-level particle as

```math
|\psi\rangle = \psi_0 |0\rangle + \psi_1 |1\rangle
```

Where $\psi_0$ and $\psi_1$ are complex coefficients, so that $|\psi\rangle$ is a linear combination of orthonormal basis elements (like any good vector should be). Then we can write

```math
|\psi\rangle = \begin{bmatrix} \psi_0 \\ \psi_1 \end{bmatrix}
```

And we can dig a little deeper into these unitaries and observables:

```math
\begin{align*}
|\phi\rangle &= U | \psi \rangle \\
&= U (\psi_0 | 0 \rangle + \psi_1 | 1 \rangle) \\
&= (U_{0 \to 0}\psi_0 + U_{1 \to 0}\psi_1) | 0 \rangle + (U_{0 \to 1} \psi_0 + U_{1 \to 1}\psi_1) | 1 \rangle \\
&= U \begin{bmatrix} \psi_0 \\ \psi_1 \end{bmatrix} \\
&= \begin{bmatrix} U_{00} & U_{01} \\ U_{10} & U_{11} \end{bmatrix} \begin{bmatrix} \psi_0 \\ \psi_1 \end{bmatrix} \\
&= \begin{bmatrix} U_{0  0}\psi_0 + U_{01}\psi_1 \\ U_{10}\psi_0 + U_{11}\psi_1 \end{bmatrix} \\
\end{align*}
```

So in the end we've recovered basic matrix-vector algebra. You might object, hey, isn't Julia a one-based indexing language? Are you really going to force us to use this zero-based indexing? Well, unfortunately (?), that's the convention in quantum mechanics.

What's nice about this is we can immediately apply all the tools from `LinearAlgebra.jl`, which has great support for complex numbers as well.

Let's do some exercises!
"

# ╔═╡ c2f21849-9670-444b-b848-ca5030c094ba
md"
Undisable the cells below as necessary -- they're disabled for now to keep the notebook from breaking!
"

# ╔═╡ 44cc8818-fbea-4acd-bbc1-f75fe40d2bed
# initialize and normalize a random single-particle state vector ψ
# remember that it should be complex!
ψ = 

# ╔═╡ e93eb661-234d-49ad-bb61-c09847ca4f33
md"
Let's look at some common unitaries applied to a single particle state, the so-called Pauli operators `I`, `X`, `Y`, and `Z`.
"

# ╔═╡ 79412f33-0846-4bcf-b44d-e2cb3dd195b8
const I = ComplexF64.([1 0; 0 1])

# ╔═╡ 39004e33-9030-4adb-8655-f65858ad9bd2
const X = ComplexF64.([0 1; 1 0])

# ╔═╡ d39ec526-ae5b-4773-b8d9-3ac3d1e426ec
const Y = ComplexF64.([0 -im; im 0])

# ╔═╡ 553cf3e5-640e-43ba-baff-e84fb6370c9f
const Z = ComplexF64.([1 0; 0 -1])

# ╔═╡ 213c4ea8-00a4-4e4a-9999-0246fceed042
md"
Try applying each of these to your randomly generated ψ above:
"

# ╔═╡ c9fd46bc-7e59-4b68-9b07-b2fe348d267c
#=╠═╡
X*ψ
  ╠═╡ =#

# ╔═╡ 358c25bb-757d-42bb-aff0-ed659ab4f689
#=╠═╡
Y*ψ
  ╠═╡ =#

# ╔═╡ 2d143124-266f-4b1a-a6b6-67286b0d2ec4
#=╠═╡
Z*ψ
  ╠═╡ =#

# ╔═╡ 4f53e0ce-1aae-44e5-91b2-6f8a5079f627
md"
There's also the Hadamard operator:
"

# ╔═╡ 0965928d-91d5-429e-b73b-f447a0207c59
H = 1/√2 * ComplexF64.([1 1; 1 -1])

# ╔═╡ 602e3a8d-7387-4ad7-9e3c-03ecf4cde890
#=╠═╡
H*ψ
  ╠═╡ =#

# ╔═╡ ecc91b02-36fd-4762-9551-93b47a7cc384
md"
Some things we can quickly notice here:
- `X` is analogous to a `NOT` operation, that flips $|0\rangle$ to $|1\rangle$ and vice-versa
- `Y` does something similar but changes the coefficients a bit
- `Z` seems to have $|0\rangle$ and $|1\rangle$ as eigenvectors...

Let's look at the eigendecompositions of each.
"

# ╔═╡ 6006aedd-c173-4bc2-b776-f0161f0199f4
eigvals(X)

# ╔═╡ 8b522aaf-1b97-4972-9e8c-8bd604828d80
eigvecs(X)

# ╔═╡ d0491da7-3734-4728-a7eb-3572debad1c7
eigvals(Y)

# ╔═╡ 35658174-1bf3-42ff-b309-878fbcf03cc4
eigvecs(Y)

# ╔═╡ 088b6487-91e8-442b-8df1-ec5aefeb03da
eigvals(Z)

# ╔═╡ 74841f09-a1e4-4dbd-ad4b-1014d72321a9
eigvecs(Z)

# ╔═╡ 14a1600e-aeb5-412e-9c39-81a6fa8abf3b
md"
Looking carefully, we can see that none of these 3 operators share an eigenbasis. Another way of saying this is that they don't commute, so that
$[X, Y] = XY - YX \neq 0$

Operators that don't commute **cannot** be simultaneously measured in an experiment, which is a peculiar feature of quantum mechanics. The identity matrix commutes with all operators, of course. In our classical idealization, however, we can take expectation values of non-commuting observables since we're allowing ourselves the fiction of infinite trials.

We can also build up more complex operators through linear combination, like we did for the state vector:
"

# ╔═╡ f8d6d601-7737-48f2-9054-69d97b694423
O1 = X + Y

# ╔═╡ 53f5bdd3-660f-4e6b-9c78-67cf379a4f6d
md"
Let's compute the expectation value of this observable:
"

# ╔═╡ 08726f6b-3f47-49c3-b7a3-3e55e4209a22
dot(ψ, O1, ψ)

# ╔═╡ e58924e6-7fd6-41d2-9c48-dd839a5c7977
md"
It's pretty helpful that `LinearAlgebra` already provides this for us, and even conjugates the lefthand `ψ`! Now we can consider how this operator `O1` acts on the states $|0\rangle$ and $|1\rangle$:
"

# ╔═╡ b132f748-5af0-4e9e-96f3-ee9f68450f8a
O1 * [1, 0]

# ╔═╡ 00cd7d24-abb8-44d3-93e2-c522d1d75cb4
O1 * [0, 1]

# ╔═╡ 46f5da23-eebf-4166-8d91-0399a4050854
md"
So, clearly, $|0\rangle$ and $|1\rangle$ are **not** \"eigenstates\" of this observable `O1`. For a small $2 \times 2$ matrix, like this, we can easily diagonalize `O1`:
"

# ╔═╡ b9f25bb9-0aeb-48c5-9050-60b712e355ee
eigvals(O1)

# ╔═╡ effe8ef7-700b-45c6-a4a8-0348e4831dc4
eigvecs(O1)

# ╔═╡ 60e7ca36-c3e8-444f-86f9-046382557d68
md"
The eigenvectors (eigenstates) of `O1` (or any other Hermitian observable) represent the possible outcomes of the collapse induced by measurement, and the eigenvalues the measurement outcomes. If a Hermitian observable like `O1` describes the potential energy fields and interactions between the various particles, it's called a \"Hamiltonian\" which is usually written $H$ (yes, it's the same letter as the Hadamard gate, very confusing).

By diagonalizing the Hamiltonian, we can find the full \"spectrum\" of possible states and their energies and understand all the physics of the system. The eigenvalues of the Hamiltonian are its \"energies\". Usually the systems we're interested in spend most of their time in their lowest-energy (smallest eigenvalue) state, which is called the \"groundstate\". A huge part of studying quantum physics is finding ways to diagonalize a really big matrix.
"

# ╔═╡ c1c6207d-8761-451c-9d1c-3670f5682a76
md"
## Putting particles together

What if we want to work with ensembles of more than one particle? We can \"combine\" the wavefunctions of two (or many!) quantum objects using the tensor product $\otimes$. Remember that $\otimes$ takes $v \in V$ and $w \in W$, where $V$ and $W$ are vector spaces, and maps $(v, w) \to v \otimes w \in V \otimes W$, the combined, larger vector space. For two particles, we can generate **four** orthonormal basis states:

```math
\begin{align*}
|0\rangle \otimes |0\rangle =& |00\rangle \\
|0\rangle \otimes |1\rangle =& |01\rangle \\
|1\rangle \otimes |0\rangle =& |10\rangle \\
|1\rangle \otimes |1\rangle =& |11\rangle \\
\end{align*}
```

Usually we omit the $\otimes$ to save ourselves some writing/typing. 
Every time we add another particle, the size of the vector space *doubles. 
You can see already why simulating quantum mechanics classically is hard -- the number of possible states grows as $2^N$, where $N$ is the total number of particles -- and so even for 30-40 particles you will need an HPC system to diagonalize an operator acting on the full system.

### Applying unitaries to these joint states

Suppose we've got a state $|\psi_2\rangle$ on two particles and we want to apply a unitary $U_0$ to just one of them, say particle 0. $U_0$ is a $2\times2$ object we're trying to apply to a length $4$ vector. Is there a way we can do so easily? In fact we can exploit the same $\otimes$ operation.

```math
U_0 |\psi_2\rangle = U_0 \otimes I_1 |\psi_2\rangle
```

Usually we don't write out all the $\otimes I$ but remember they're \"there\".
"

# ╔═╡ 095b6f2f-a772-40c7-8555-f76a4eb65899
md"
## Exercises

Let's try applying some single-particle unitaries to more complex states. First, we need to pick an **ordering** for the particles, so we can consistently apply unitaries to the intended targets. This is related to the computer science problem of [endianness](https://en.wikipedia.org/wiki/Endianness) and we'll return to it later. For now, let's say the leftmost particle in the tensor product is particle 0, and the one to its right is particle 1, etc. Then:
"

# ╔═╡ ceaf7754-69a3-4586-9140-2d001b18cbf2
kron(I, X) * [0, 0, 0, 1]

# ╔═╡ 34122d1c-e568-4006-95c2-8fa764596d61
kron(X, I) * [0, 0, 0, 1]

# ╔═╡ 140ef143-c2b6-45e0-a2bd-8d207437f66f
md"
What do you notice about which particle `X` acts on here?
"

# ╔═╡ 119b5fc0-ea60-4dbf-9395-36bff547c9c2
md"
Now we want a more systematic way to apply (single target) unitaries to arbitrary statevectors. Let's write a function `apply_gate_kron` which uses the `kron` function to apply a single-target unitary, for instance any of `X`, `Y`, `Z`, `I` or `H` above, to an arbitrary state vector `ψ`:
"

# ╔═╡ a953d052-bf60-47b7-90f4-5688d27e8700
function apply_unitary_kron(ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_target::Int)
	n_target  = Int( log2(length(ψ)) )
	all_gates = [I for qubit in 1:n_qubits]
	...
	full_gate = ...
	return full_gate * ψ
end

# ╔═╡ 9ef8e621-e762-400d-8346-bc4077f872c9
md"
Now we need to check our work. We can see that
```math
\begin{align*}
|\phi_2\rangle &= X_1 |\psi_2\rangle \\
&= X_1 (\psi_0 |00\rangle + \psi_1 |01\rangle + \psi_2|10\rangle + \psi_3|11\rangle) \\
&=  \psi_1 |00\rangle + \psi_0 |01\rangle + \psi_3 |10\rangle + \psi_2|11\rangle \\
\end{align*}
```

Is that similar to what you observe from your function? What should you expect to get as a result if you apply `Z` instead?
"

# ╔═╡ eb043f42-baca-4f7d-b456-de77e43b97dc
md"""
### Multi qubit unitaries

Let's look a little closer at some multi-target unitaries, such as `SWAP`. As the name implies, this swaps the states between the targets.
```math
\begin{align*}
\mathrm{SWAP} |\psi_2\rangle &= \mathrm{SWAP}\left(\psi_0 |00\rangle + \psi_1 |01\rangle + \psi_2 |10\rangle + \psi_3|11\rangle\right) \\
&= \psi_0 |00 \rangle + \psi_1 |10\rangle + \psi_2 |01\rangle + \psi_3 \rangle \\
\end{align*}
```
We can write this in matrix form as:
```math
\mathrm{SWAP} = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix}
```

One interesting thing to note about this: can you write `SWAP` as a Kronecker product of two single-target unitaries?

How would you modify `apply_unitary_kron` to handle gates on multiple (adjacent) targets?
"""

# ╔═╡ 570df816-54af-4bc5-83ee-ee3028ef407d
function apply_unitary_kron(ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_targets::Int...)
end

# ╔═╡ 59d71c88-0428-4302-88ab-8867be5f299c
md" We'll define a couple other common 2-target unitaries now. "

# ╔═╡ ad7c7071-8fe5-4182-b156-acd0754dad40
const SWAP = ComplexF64.([1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1])

# ╔═╡ 5825456c-e279-4597-b265-816557495b52
const CNOT = ComplexF64.([1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])

# ╔═╡ ec03a598-c8d3-4163-9995-4aaa47bffaa5
md"
### Computing expectation values

In order to compute correlation functions or other quantities of interest, we need to be able to compute expectation values of Hermitian linear operators (observables). In Dirac notation, we'd write this as:

```math
\langle O \rangle = \langle \psi | O | \psi \rangle
```

This is an inner product. One way to implement this would be to first compute
```math
|\phi\rangle = \hat{O}|\psi\rangle
```
then
```math
\langle O \rangle = \langle \psi | \phi \rangle
```

Although, as it happens, Julia's `LinearAlgebra` standard library has a helpful `dot` function that can compute $\langle x | A | y \rangle$ in one invocation, *including* properly conjugating `x` if it is complex-valued. Again, similar to unitaries, for now we can construct an observable that spans all qubits using `kron`.
"

# ╔═╡ 3f7a9f08-d9e0-4940-8737-88fbdd4b02c8
function compute_expval_kron(O::Matrix{ComplexF64}, o_qubit::Int, ψ::Vector{ComplexF64})
	n_qubits = Int( log2(length(ψ)) )
	all_observables = [I for qubit in 0:n_qubits - 1]
	...
	full_O = ...
	return dot(ψ, full_O, ψ)
end

# ╔═╡ 21096cfe-57d4-4a4c-8e81-550bb36b88f1
md"
Let's again check that we get the correct answer here. Working through the algebra, we see that
```math
\begin{align*}
|\phi_2\rangle =& \frac{1}{\sqrt{2}} |01\rangle - \frac{1}{\sqrt{2}} |10\rangle \\
\langle Z_0 \rangle =& \langle \phi_2 | \hat{Z_0} | \phi_2 \rangle \\
=& \frac{1}{2} \left(\langle 01 | \hat{Z}_0 | 01 \rangle - \langle 10 | \hat{Z}_0 | 01 \rangle - \langle 01 | \hat{Z}_0 | 10 \rangle + \langle 10 | \hat{Z}_0 | 10 \rangle  \right) \\
=& \frac{1}{2} \left(1 - 0 - 0 - 1\right) \\
=& 0 \\
\end{align*}
```

How does this compare to your function?

It might be worth repeating this with various other observables and states to make sure your function is right.

"

# ╔═╡ dbaf48ed-35f0-4772-85ff-932b093ca40c
md"
### Pros/cons of the `kron` approach

It's relatively easy to write a quick function which `kron`-s together a unitary with all its identities so we can use the BLAS `gemv`. However, it presents some obvious problems:

- The memory usage is very unfavorable, because we're building a $2^N \times 2^N$ matrix in order to apply a (for now) $2 \times 2$ object to a length $2^N$ vector
- We're also wasting many compute cycles computing many `kron` operations, most of which involve the identity matrix
- It can't handle unitaries/observables with **multiple, non-contiguous** targets (like `(2, 5)`) very easily

However, these are still useful as quick checks.
"

# ╔═╡ cdc1adce-3fbe-41f0-ad11-c2c7975b456e
md"
### Applying unitaries to a state vector (less naive approach)

Let's return to our 2 qubit state vector $|\psi_2\rangle$:

```math
|\psi_2\rangle = \psi_0 |00\rangle + \psi_1 |01\rangle + \psi_2 |10\rangle + \psi_3 |11\rangle
```

When looking at this 4 element vector, we note that we could also reshape it into a `2 x 2` matrix, such that each dimension corresponds to one particle. Let's show this:

```math
| \psi_2 \rangle = \begin{bmatrix} \psi_0 & \psi_2 \\ \psi_1 & \psi_3 \end{bmatrix}
```

You can see, given our encoding above, that the rows of this matrix correspond to the two possible states of particle 0, and the columns to particle 1.

Now suppose we had 3 particles, so a state vector with 8 elements.

```math
| \psi_3 \rangle = \psi_0 |000\rangle + \psi_1 |001\rangle + \psi_2 |010\rangle + \psi_3 |011\rangle + \psi_4 |100\rangle + \psi_5 |101\rangle + \psi_6 |110\rangle + \psi_7 |111\rangle
```

We can reshape this into a `2 x 4` or `4 x 2` object. This will allow us to apply unitaries without performing lots of unnecessary outer products.

Now we'll need to think a little bit carefully about how Julia arrays are laid out and how this corresponds to our qubit ordering. Julia arrays are laid out in [column-major order](https://en.wikipedia.org/wiki/Row-_and_column-major_order). Let's take a look at how reshaping our state vector might affect things:
"

# ╔═╡ 4eea53a1-58ff-46ce-98e1-6176e4aabd8e
# unnormalized - for demonstation purposes only!
ψ3 = [0.1, 0.1im, 0.2, -0.2im, 0.3, 0.3im, 0.4, -0.4im];

# ╔═╡ bff46783-0df4-4b46-af26-f92c61f50b35
for (ix, c) in enumerate(ψ3)
	println("Index: $ix, $c")
end

# ╔═╡ bc58a3c6-e250-48a6-ae4c-aa489cf40a4a
ϕ3 = reshape(ψ3, (2, 2, 2))

# ╔═╡ 48a289f2-7ff0-47b7-838d-cf0191cf2fde
φ3 = reshape(ψ3, (4, 2))

# ╔═╡ 458fae9e-ad9e-4e38-875d-675386e1daef
ω3 = reshape(ψ3, (2, 4))

# ╔═╡ 40803b98-a790-47df-813f-a558f6d6cfec
md"
Let's now examine how we can use this to apply unitaries more efficiently. Consider again applying `X` to various targets. For safety, we'll work out by hand what the answer ought to be:

```math
\begin{align*}
\hat{X}_0|\psi\rangle =& \hat{X}_0 \left(0.1 |000\rangle + 0.1\imath |001\rangle + 0.2 |010\rangle - 0.2\imath |011\rangle + 0.3 |100\rangle + 0.3\imath |101\rangle + 0.4 |110\rangle - 0.4\imath |111\rangle\right) \\
=& 0.1 |001\rangle + 0.1\imath |000\rangle + 0.2 |011\rangle - 0.2\imath |010\rangle + 0.3 |101\rangle + 0.3\imath |100\rangle + 0.4 |111\rangle - 0.4\imath |110\rangle \\
=& 0.1\imath |000\rangle + 0.1 |001\rangle - 0.2\imath |010\rangle + 0.2 |011\rangle + 0.3\imath |100\rangle + 0.3 |101\rangle - 0.4\imath |110\rangle + 0.4 |111\rangle\ \\
\hat{X}_1|\psi\rangle =& 0.1 |010\rangle + 0.1\imath |011\rangle + 0.2 |000\rangle - 0.2\imath |001\rangle + 0.3 |110\rangle + 0.3\imath |111\rangle + 0.4 |100\rangle - 0.4\imath |101\rangle \\
=& 0.2 |000\rangle - 0.2\imath |001\rangle + 0.1 |010\rangle + 0.1\imath |011\rangle + 0.4 |100\rangle - 0.4\imath |101\rangle + 0.3 |110\rangle + 0.3\imath |111\rangle \\
\hat{X}_2|\psi\rangle =& 0.1 |100\rangle + 0.1\imath |101\rangle + 0.2 |110\rangle - 0.2\imath |111\rangle + 0.3 |000\rangle + 0.3\imath |001\rangle + 0.4 |010\rangle - 0.4\imath |011\rangle \\
=& 0.3 |000\rangle + 0.3\imath |001\rangle + 0.4 |010\rangle - 0.4\imath |011\rangle + 0.1 |100\rangle + 0.1\imath |101\rangle + 0.2 |110\rangle - 0.2\imath |111\rangle    \\
\end{align*}
```

In this new approach, $|ψ\rangle$ is reshaped such that the 2nd dimension represents the states on target 0. Here's how we can check:
"

# ╔═╡ 5c23c8e9-fb96-4f66-b23a-67ab458abaed
function apply_unitary_reshaped_bad(ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_qubit::Int)
	ψ_reshaped = reshape(ψ, (4, 2))
	return vec(ψ_reshaped * unitary)
end

# ╔═╡ d1f90185-220a-4443-b2ee-96e1b3963ebb
ϕ_reshaped1 = apply_unitary_reshaped_bad(ψ3, X, 0)

# ╔═╡ 6fc672f7-e72c-4060-a2a5-7a2f047f844c
# uncomment me when your `apply_unitary_kron` is working!
# ϕ_kron1 = apply_unitary_kron(ψ3, X, 0)

# ╔═╡ 41701c5f-6f7c-4c8f-95a4-b75f6512cb04
md"
Great! Looks like they match. But what if we apply `X` to a different target, say 1?
"

# ╔═╡ 37796048-3de0-40e7-b7aa-e76612e96b84
# uncomment me when your `apply_unitary_kron` is working!
# ϕ_kron2 = apply_unitary_kron(ψ3, X, 1)

# ╔═╡ 4a65b30f-3db8-4a5f-b126-99d3a7c7431a
ϕ_reshaped2 = apply_unitary_reshaped_bad(ψ3, X, 1)

# ╔═╡ d3d8c758-25a5-4187-a736-119ae66ab6b5
md"
Uh oh. You will likely see a discrepancy! Why?

The problem is that we reshaped without *permuting*. As said above, if we simply reshape as we did in `apply_unitary_reshaped1`, we're implicitly applying the gate to target 0 every time. We need to **permute** the dimensions of the input state vector $|\psi\rangle$ (and be careful to permute back!) in order to handle unitaries appropriately.
"

# ╔═╡ 67b858fe-c936-4eba-bab8-33eb992368c2
function apply_unitary_reshaped(ψ::Vector[ComplexF64}, unitary::Matrix{ComplexF64}, unitary_target::Int)
	n_targets   = Int( log2(length(ψ)) )
	ψ_reshaped  = reshape(ψ, ntuple(i->2, n_targets))
	permutation = collect(1:n_targets)
	
	permutation[end] = ...
	permutation[gate_qubit + 1] = ...

	ϕ           = permutedims(ψ_reshaped, permutation)
	ϕ_reshaped  = reshape(ϕ, ...)
	ϕ_reshaped *= gate
	ϕ           = reshape(ϕ_reshaped, ntuple(i->2, n_qubits))
	ψ_reshaped  = permutedims(ϕ, permutation)	
	ϕ           = reshape(ψ_reshaped, 2^n_targets)
	return ϕ
end

# ╔═╡ 18335cf9-0168-4e70-8206-8adeda8d9f20
# ϕ_reshaped3 = apply_unitary_reshaped(ψ3, X, 1)

# ╔═╡ e6ced8f2-5c8a-459b-a5fb-4dd665d7c007
# ϕ_kron3 = apply_unitary_kron(ψ3, X, 1)

# ╔═╡ cbc9cee3-ed2c-402f-b2f5-2f75e02c7c89
# ϕ_reshaped4 = apply_unitary_reshaped(ψ3, X, 2)

# ╔═╡ df786bec-af6c-4d1e-8d31-a94b54c6e8e2
# ϕ_kron4 = apply_unitary_kron(ψ3, X, 2)

# ╔═╡ 82b37a98-fdd5-4575-aa1e-4256e274084a
md"
This matches up with what we calculated above, and our two functions should be consistent with each other. Huzzah!
"

# ╔═╡ f6f1e2b6-c2bc-49e6-923a-caa4cfe39ab2
md"
### Exercise

How would you modify `apply_unitary_reshaped` to handle unitaries on multiple targets, including **non-contiguous** (non-adjacent) targets?
"

# ╔═╡ c2f32fdd-4594-445b-b0ea-e9cdefd38516
md"
### Performance on the brain

Above, I claimed that our `kron` approach has lots of performance problems. Is this reshape-permute-reshape approach any better? Rather than speculating, let's find out. We'll define some `runner` functions for easy of benchmarking.
"

# ╔═╡ fd6fa261-146e-4892-9ee5-4b21bf25568d
ψ_small() = normalize!([0.1, 0.1im, 0.2, -0.2im, 0.3, 0.3im, 0.4, -0.4im])

# ╔═╡ fb843ec4-9f39-49b8-90a5-09bf37a8290c
kron_runner(ψ) = apply_unitary_kron(ψ, X, 2)

# ╔═╡ e5e3e24c-1f3a-4990-87e7-7461c30f16d4
reshaped_runner(ψ) = apply_unitary_reshaped(ψ, X, 2)

# ╔═╡ 7a1afc7d-bfa4-4714-bd8e-ade53910712d
# @b ψ_small() kron_runner

# ╔═╡ 6e3e6ae1-f03d-4a3c-9162-583223f30f02
# @b ψ_small() reshaped_runner

# ╔═╡ 28143f2b-a14a-436e-baa8-d2817308b7b0
md"
Reshaping isn't doing so well for a small (3-particle) state vector. What about something larger?
"

# ╔═╡ c2161781-92d9-4610-990e-15fb5bec5e11
ψ_big() = normalize!(rand(ComplexF64, 2^12));

# ╔═╡ 70e59ec9-6a22-4946-8191-7ead62f94c0a
# @b ψ_big() kron_runner

# ╔═╡ 41f86858-fed6-49ae-b363-c6e4f7eba516
# @b ψ_big() reshaped_runner

# ╔═╡ cb9668cc-26e3-43e4-8309-13849dd0f422
md"
Now we do see a difference... partly because of allocations! But not only for that reason - matrix-vector multiplication scales as (roughly) $\mathcal{O}\left(n^3\right)$, so avoiding constructing massive matrices and multiplying them is in our interest.

Another important lesson here: **always** benchmark (or, rather, chairmark!). Our intuitions about physics and computation are often wrong.
"

# ╔═╡ 09af0ec2-b9b1-4c2f-8319-91f8bcafa989
md"
### Exercise

Can you adjust the `compute_expval_kron` function above to use this `reshape`-`permute`-`reshape` scheme?
"

# ╔═╡ 4823cc83-caf9-4afc-95da-868f2dfc95c2
function compute_expval_reshaped()

end

# ╔═╡ 5506ccf5-c89e-4b1b-9a3f-e1c3df9c9464
md"
## Becoming more sophisticated over time

Although we've achieved *better* performance with our new approach, we can in fact do even more. The trick lies in realizing that:
- `permutedims` requires a copy
- If we are clever and a bit careful about using indices, we can avoid this copy
- As a bonus, we can use (and control) multithreading

How is this possible? By exploiting the fact that *integers* on classical computesr are also represented as *bitstrings* \"under the hood\". We've already set the stage for this with our coefficient labelling - $\psi_0$, $\psi_3$, and the like. Let's dig a little deeper.

Julia has several inbuilt functions which we can use to inspect how integers are represented internally. We'll focus on [`digits`](https://docs.julialang.org/en/v1/base/numbers/#Base.digits) and [`bitstring`](https://docs.julialang.org/en/v1/base/numbers/#Base.bitstring). First, we'll examine indices `0` through `7`, for our 3-particle state vector. (Why do you think we start **these** indices at 0?)
"

# ╔═╡ c963ec08-f353-45fb-8bbb-9b5480a47f98
for ix in 0:7
	println("Digits of index $ix: $(digits(ix, pad=3, base=2))")
end

# ╔═╡ adcd9a23-5197-4439-a19c-b968dcab4f76
for ix in 0:7
	println("Full bitstring of index $ix: $(bitstring(ix))")
end

# ╔═╡ fdb0a830-e33d-4391-a61d-9959348e40c7
md"
`bitstring` shows the **full** representation of an integer in memory. What do you notice about this representation, considering our previous discussion about [endianness](https://en.wikipedia.org/wiki/Endianness)?

#### Brief review of bit-shifting
All integers, floats, indeed all numbers are represented in computer memory as *bytes*, which are groups of 8 *bits*. Thus, an `Int64` in Julia is composed of **eight** bytes, and an `Int32` of **four** bytes.

Here we need to introduce one more concept: **bit-shifting**.

In Julia, as in many other languages, we have two bit shift operators: [`>>`](https://docs.julialang.org/en/v1/base/math/#Base.:%3E%3E) and [`<<`](https://docs.julialang.org/en/v1/base/math/#Base.:%3C%3C). What do each of these do?
"

# ╔═╡ 725d85e0-331d-4241-bc8d-68849654925d
for ix in 0:7
	println("Full bitstring of index $ix: $(bitstring(ix))")
	println("Full bitstring of index $ix shifted left $(bitstring(ix << 1))")
	println("Full bitstring of index $ix shifted right $(bitstring(ix >> 1))")
	println()
end

# ╔═╡ 11180e99-04f6-4051-bb58-ef93278037d5
md"
That's very nice, but how can we use this to compute unitary applications or expectation values more efficiently?

Consider again the application of a generic single target unitary $U$ on target 0. The matrix representation of $U$ looks like:

```math
U = \begin{bmatrix} u_{00} & u_{01} \\ u_{10} & u_{11} \end{bmatrix}
```

So, how can we apply this in an allocation-free way? Let's take a look at our 3-particle example above. We saw that by reshaping an `(8,1)` vector into a `(4,2)` matrix, we could target particle 0. In fact, we can perform the same operation **without reshaping** using bitshifting, and in a more general way.

This is somewhat subtle, so let's go through it step by step.

For a `2^N`-length statevector, and a single target unitary, we need to \"connect\" states $|0\rangle$ and $|1\rangle$ on that target -- meaning there are $2^{N-1}$ \"connections\" to make (as we saw in the reshaping above). First, we can examine:

```julia
for ix in 0:2^n_particles
	...
end
```

As we did above. But we see, by considering the bitstrings, that we'll \"double target\" the particle of interest, because we pick up both the bitstrings that contain a `0` and a `1` on that particle. Instead, we can consider 

```julia
for ix in 0:2^(n_targets-1)
	...
end
```

But how to touch the target we do want? Let's say we want to apply a unitary to particle 1 on a 3-qubit statevector - if you print the `bitstring`s of all integers `0:4`, you'll see that particles 0 and 1 would be touched - but not particle 2. We can \"insert\" a zero bit **at the appropriate particle**.

```julia
function expand_int(ix::Ti, target) where {Ti}
    left  = (ix >> target) << target
    right = ix - left
    return (left << one(Ti)) ⊻ right
end

for ix in 0:2^(n_targets-1)
	expand_int(ix, 1)
end
```

What? What does this actually do - let's take a closer look:
"

# ╔═╡ 13b791c4-68bb-47c9-9464-09f500e16eb0
function expand_int(ix::Ti, target) where {Ti}
    left  = (ix >> target) << target
    right = ix - left
    return (left << one(Ti)) ⊻ right
end

# ╔═╡ 3fcfe42e-407d-4e38-b215-3db76d3a3815
for ix in 0:4
	println("bitstring(ix): $(bitstring(ix))), bitstring expanded ix: $(bitstring(expand_int(ix, 1)))")
end

# ╔═╡ 1077c26d-a266-4da2-b80c-ee44c6596be3
md"
So we bumped the bits to the left starting at index 1? Reckoning from the left? If you're still confused, it can be worth playing with a variety of integers and \"expansion targets\" to get a more intuitive feel for what this is doing.

Now we also need a way to \"connect\" to the 1-valued indices. This can be achieved by \"flipping\" the target we want to act on, from 0 to 1. This is simpler than the expansion operation:

```julia
flip_bit(ix::Ti, target) where {Ti} = ix ⊻ (one(Ti) << target)
```

This `⊻` is `XOR`, or \"exclusive or\" (one or the other, but not both), such that:
- `0 ⊻ 0 = 0`
- `0 ⊻ 1 = 1`
- `1 ⊻ 0 = 1`
- `1 ⊻ 1 = 0`

The shifting of `one(Ti)` is to flip the appropriate bit - again, try looping through a few integers to see how this works.

With this, we have the tools we need to write an efficient method for applying arbitrary single qubit unitaries.
"

# ╔═╡ 4c7bb461-90c5-4f61-81dd-92326f084a10
flip_bit(ix::Ti, target) where {Ti} = ix ⊻ (one(Ti) << target)

# ╔═╡ 040d94cc-4d0b-4cda-8a91-6794dbd5f3f6
function apply_unitary_shifting_copy(ϕ::Vector{ComplexF64}, ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_target::Int)
	n_particles = Int( log2(length(ψ)) )
	for ix in 0:2^(n_particles-1)-1
		amplitude_0 = expand_int(ix, unitary_target)
		amplitude_1 = flip_bit(amplitude_0, unitary_target)
		# Julia is one-indexed!
		amplitude_0 += 1
		amplitude_1 += 1
		old_ψ_0 = ψ[amplitude_0]
		old_ψ_1 = ψ[amplitude_1]
		ϕ[amplitude_0] = unitary[1, 1] * old_ψ_0 + unitary[1, 2] * old_ψ_1
		ϕ[amplitude_1] = unitary[2, 1] * old_ψ_0 + unitary[2, 2] * old_ψ_1
	end
	return ϕ
end

# ╔═╡ c143c0ac-4f27-471c-876e-5472e4addea3
md"
Let's check again that this returns correct results.
"

# ╔═╡ 18edcf29-a3b8-4422-a5f0-afc1e58cc013
apply_unitary_shifting_copy(copy(ψ3), ψ3, X, 0)

# ╔═╡ 20335f3e-16e8-47ff-abca-37f251771be7
# apply_unitary_kron(ψ3, X, 0)

# ╔═╡ 9f650edc-835d-4a78-9c50-c38d15e4b7d8
apply_unitary_shifting_copy(copy(ψ3), ψ3, X, 1)

# ╔═╡ 5bc1beb8-8cf0-4d68-b8fd-2cd91429b86c
# apply_unitary_kron(ψ3, X, 1)

# ╔═╡ bea8e5ba-55f9-4665-a8fa-3bb2dbcf87b6
apply_unitary_shifting_copy(copy(ψ3), ψ3, X, 2)

# ╔═╡ 179c9b82-f5ed-4528-aa27-915f695e5824
# apply_unitary_kron(ψ3, X, 2)

# ╔═╡ 8e8c54e3-2d76-49ed-994a-55f77432c892
md"
Again, this should match your `kron` based results. In our example here, we created an unnecessary copy of $|ψ\rangle$ for testing convenience. Can you rewrite the function to be entirely inplace?
"

# ╔═╡ af3a39ae-4951-4fd4-96aa-9bcf396c548b
function apply_unitary_shifting(ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_target::Int)

end

# ╔═╡ 8fbb3671-2860-4004-a8eb-7e4464dfb4d3
md"
Our approach of stepping over `2^(n_qubits - n_gate_qubits)` amplitudes ensures we don't \"double touch\" any indices. Let's now compare the performance using a copy-free approach.
"

# ╔═╡ 34734787-a4c0-42f1-94cb-d58a25ed29c8
# @b ψ_small() kron_runner

# ╔═╡ 0514ec20-7d2e-4a89-af75-4b710ccdba21
# @b ψ_small() reshaped_runner

# ╔═╡ 39f46cef-070f-4acb-b431-0c7f68fbb78d
# @b ψ_small() shifting_runner

# ╔═╡ 0404b97e-9452-438d-bdbc-6dd658e73f91
md"
Even for a very small state vector, this approach works nicely -- can you suggest a reason why? Let's now examine our larger statevector.
"

# ╔═╡ fc653ce9-228b-41b6-acdf-e3b90d060179
# @b ψ_big() kron_runner

# ╔═╡ e047212d-9841-4528-9bcb-e3e3fdbfdb7f
# @b ψ_big() reshaped_runner

# ╔═╡ c63b7710-7c6f-4e0c-b51c-5c9a6a628af4
# @b ψ_big() shifting_runner

# ╔═╡ 42f468cf-ae6a-432c-8b27-b3d28681d38f
md"
Another advantage of the bitshifting approach is that we can use multithreading. In fact, the `LinearAlgebra` routines we are calling in `apply_unitary_kron` and `apply_unitary_reshaped` already use BLAS behind the scenes, which does have support for multi-threading.

Is writing our own threading logic for `apply_unitary_shifting` worthwhile? Let's try it and benchmark to determine the answer.
"

# ╔═╡ b756efcf-5ccb-49c7-8aa7-f2e646b21f5a
md"
## Exercises

Try some approaches to improving the performance of your single-target unitary function:
- Multithreading with your favorite threading package (Base's `Threads`, `OhMyThreads.jl`, something else)
- Using `@inbounds` in the `getindex`/`setindex!` portions
- Using linear vs Cartesian indices
"

# ╔═╡ aa267bc2-c39f-487b-9f69-2c4a3d6ed9f4
md"
## Multi-qubit unitaries with bitshifting

Now we're ready to venture forth into the wild, exciting world of unitaries on more than one particle. Examples of such gates are:
  - `SWAP` (introduced above)
  - [`XX`](https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.RXXGate) 
  - [`YY`](https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.RYYGate)
  - [`ZZ`](https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.RZZGate)
  - [`CPhaseShift`](https://quantum.cloud.ibm.com/docs/en/api/qiskit/qiskit.circuit.library.CPhaseGate) and friends

In this section, you're going to have less step-by-step guidance, but hopefully you can extend what we've already done for a single particle. Again, it will probably be helpful to write an `apply_unitary_kron` (if you didn't already) which can handle contiguous targets as a correctness checker.

One thing to consider, when using `expand_int`, is the order of the targets. Let's look at a small test case:
"

# ╔═╡ 6024d6e2-316b-4daa-ae4b-3ad9e3824b7c
begin
	a = Int8(5)
	println("Initial bitstring: $(bitstring(a))")
	# let's expand this at qubits 1 and 3
	println("Expanded in order (1, 3) bitstring: $(bitstring(expand_int(expand_int(a, 1), 3)))")
	println("Expanded in order (3, 1) bitstring: $(bitstring(expand_int(expand_int(a, 3), 1)))")
end

# ╔═╡ ac6f11ac-1acb-46d1-9b69-0b76380455db
md"
The results are **not** the same! Thus, we'll need to be careful of what order we insert bits. Let's look step by step to see what's happening here:
"

# ╔═╡ 1dcffec3-d7a8-4db8-a8e1-5a7e56e04ac9
bitstring(expand_int(Int8(5), 1))

# ╔═╡ 3579848e-2d11-4ae0-b1eb-f49879d3e948
bitstring(expand_int(expand_int(Int8(5), 1), 3))

# ╔═╡ 5a483683-2e30-49e8-8021-6d733a170230
md"By inserting at position 1, we effectively shift all the digits to the left of 1 over. This means the digit that was formerly at position 3 is now at position 4."

# ╔═╡ 7eeca498-bd3b-47b9-a2b7-3ab097f5da0b
md"
## Exercise

Write a function that can efficiently apply a two-target unitary using bitshifting.

Some tips:

- For a single target function, we looped over the total number of state vector elements divided by 2. For a two target function, what would be an appropriate number of loop iterations?
- Be careful of the order in which you flip bits to generate indices for the innermost matrix-vector multiplication/update of `ψ`
- It may be worth adding a few checks to ensure the size of the input gate matrix fits the number of qubits, that the qubits are not identical, etc. and throwing errors if you encounter these.
"

# ╔═╡ c6e0f54a-c6df-457e-8219-397afb328e57
function apply_unitary_shifting(ψ::Vector{ComplexF64}, unitary::Matrix{ComplexF64}, unitary_target1::Int, unitary_target2::Int)

end

# ╔═╡ 6177482d-5078-4137-8045-dd0f08f06e92
shifting_runner(ψ) = apply_unitary_shifting(ψ, X, 2)

# ╔═╡ 226d2765-80b4-45dd-90b6-673e6ccfeed6
md"
## Expectation values using bit-shifting

Similar to what we've done above for unitary application, we can write an efficient method for computing expectation values of observables using mostly the same logic. As a reminder, we need to compute:

```math
\langle O \rangle = \langle \psi | \hat{O} | \psi \rangle
```

The $\hat{O}|\psi\rangle$ portion we already have a method for, so let's port it over to this use-case. For now we'll look at the single-target case. If we want to take advantage of threading, we need to be very careful of [race conditions](https://en.wikipedia.org/wiki/Race_condition). One option to avoid these is to use an [atomic operation](https://docs.julialang.org/en/v1/manual/multi-threading/#man-atomic-operations), which forces only one thread at a time to access the underlying data. Another option is to have each thread accumulate their own partial results (which avoids data races), then combine them at the end.
"

# ╔═╡ 6aefb4c8-495c-46fe-9ebf-0ec1cf8d8734
function compute_expval_shifting(O::Matrix{ComplexF64}, o_target::Int, ψ::Vector{ComplexF64})
	n_particles  = Int( log2(length(ψ)) )
	temp_results = zeros(Float64, Threads.nthreads())
	Threads.@threads for ix in 0:2^(n_particles-1)-1
		amplitude_0 = expand_int(ix, o_target)
		amplitude_1 = flip_bit(amplitude_0, o_target)
		amplitude_0 += 1
		amplitude_1 += 1
		@inbounds begin
			ψ_0 = ψ[amplitude_0]
			ψ_1 = ψ[amplitude_1]
			ix_dot_result = ...
			temp_results[Threads.threadid()] += real(ix_dot_result)
		end
	end
	return sum(temp_results)
end

# ╔═╡ b523f793-4e9f-4b39-a103-e3b21f9430c9
md"
Let's check this for correctness compared with our initial `kron` approach above.

Consider the rather funny-looking statevector

```math
\begin{align*}
|\psi\rangle =& \frac{1}{2}|000\rangle - \frac{\imath}{2}|101\rangle + \frac{\imath}{2} |010\rangle - \frac{1}{2}|111\rangle \\
\langle \psi | \hat{Y}_0 | \psi \rangle =& \frac{1}{2}\langle \psi | \left( \imath |100\rangle - |001\rangle - |110\rangle + \imath|011\rangle\right) \\
=& \frac{1}{4}\left(\langle 000 | + \imath \langle 101 | - \imath \langle 010 | - \langle 111 | \right) \left( \imath |100\rangle - |001\rangle - |110\rangle + \imath|011\rangle\right) \\
=& 0 \\
\langle \psi | \hat{Y}_1 | \psi \rangle =& \frac{1}{2}\langle \psi | \left( \imath |010\rangle + |111\rangle + |000\rangle + \imath|101\rangle\right) \\
=& \frac{1}{4}\left(\langle 000 | + \imath \langle 101 | - \imath \langle 010 | - \langle 111 | \right)\left( \imath |010\rangle + |111\rangle + |000\rangle + \imath|101\rangle\right) \\
=& \frac{1}{4} (1  - 1 + 1 - 1) \\
=& 0 \\
\langle \psi | \hat{Y}_2 | \psi \rangle =& \frac{1}{2}\langle \psi | \left( \imath |001\rangle - |100\rangle - |011\rangle + \imath|110\rangle\right) \\
=& \frac{1}{4}\left(\langle 000 | + \imath \langle 101 | - \imath \langle 010 | - \langle 111 | \right) \left( \imath |001\rangle - |100\rangle - |011\rangle + \imath|110\rangle\right) \\
=& 0 \\
\end{align*}
```
"

# ╔═╡ 65d54cce-f2bf-4c4b-88a3-e54aa45e22a9
ψ_test = 1/2 * [1, 0, im, 0, 0, -im, 0, -1]

# ╔═╡ 12df9728-3431-4f11-b374-f1a943461697
# compute_expval_kron(Y, 0, ψ_test)

# ╔═╡ d8ecd47b-57e7-4dc1-96dd-66566dd962be
# compute_expval_kron(Y, 1, ψ_test)

# ╔═╡ bc8d3f18-9c17-4d96-8330-d018a0074c4f
# compute_expval_kron(Y, 2, ψ_test)

# ╔═╡ dcf2b57b-23ef-4cf0-bce5-f78ef34d3fe8
# compute_expval_shifting(Y, 0, ψ_test)

# ╔═╡ 1e90828d-de25-4916-9236-dc5f8e09a495
# compute_expval_shifting(Y, 1, ψ_test)

# ╔═╡ 0421c1f8-25b9-4e87-9bbb-4141e070cbeb
# compute_expval_shifting(Y, 2, ψ_test)

# ╔═╡ 8fdd3532-0ded-4d6c-aece-fb8a85eed1c8
md"
## Exercise

Compare the performance of `compute_expval_kron` and `compute_expval_shifting` -- when does it make sense to use each?
"

# ╔═╡ 2181672f-21b9-4da4-b5cb-a298494b8dc2


# ╔═╡ 8eb5fc73-dfc4-44cb-9b97-d48dfdfafbf0
md"
## Sampling

Computing exact expectation values is all well and good, but a real quantum computer runs the same circuit many times and then measures a single output bitstring -- a \"shot\". From these shots we can compute (estimated) expectation values and correlators, but on the real quantum hardware (or in any other quantum experiment) we don't have access to the full statevector. So we would also like a way to model what the output bitstring distribution for a given shot count will look like.
"

# ╔═╡ 3609f6c7-90f8-4a4e-9cc2-275ffcb7fd30
md"
### Naive approach to sampling

We know that the elements of the statevector represent probability *amplitudes* and the actual probability of measuring a given state is 
```math
p_{\phi} = || \langle \phi | \psi \rangle ||^2
```

Assuming $|\psi\rangle$ is normalized. A common and simple approach to sampling from the vector of \"weighted probabilities\" is to take a cumulative sum of all of them, `summed_p`, normalize this new vector, then compute a random number `needle` in `[0, 1)`. Happily, Julia's [`rand`](https://docs.julialang.org/en/v1/stdlib/Random/#Base.rand) can generate such a random number for us. Then one picks the first element of `summed_p` which is larger than `needle` and that index corresponds to the sampled bitstring for the shot. Let's implement this as a quick testing utility:
"

# ╔═╡ 15f83daa-718c-40d4-8acb-8a70453bbbb8
function naive_sample(ψ::Vector{ComplexF64}, n_shots::Int)
	probabilities = abs2.(ψ)
	summed_p = ...
	shots = map(1:n_shots) do shot_ix
		...
	end
	return shots
end

# ╔═╡ d350febc-1950-4cc2-9d66-a4951b8d50a6
md"
**Hint**: you might find the [`cumsum`](https://docs.julialang.org/en/v1/base/arrays/#Base.cumsum) function quite helpful here.
"

# ╔═╡ a32288b0-06f3-478b-9416-03468ed27f25
md"
Given that we called this \"naive\", there must be some problems with it. And there are! For very low shot counts, it's not so bad, but for larger numbers of shots much better algorithms can be used. The main technique we'll look at is the use of an [alias table](https://en.wikipedia.org/wiki/Alias_method), which allows us to construct an efficient lookup table in $\mathcal{O}(n)$ (with a small prefactor), then do lookups in $\mathcal{O}(1)$. This is substantially better than having to do a $\mathcal{O}(n)$ linear search *for each shot*.

Several implementations of the alias table technique exist in the Julia ecosystem. We'll use [`AliasTables.jl`](https://aliastables.lilithhafner.com/dev/).
"

# ╔═╡ ab6259c2-098b-4bcb-bffc-c9038b2952da
function alias_sample(ψ::Vector{ComplexF64}, n_shots::Int)
	at = AliasTable(abs2.(ψ))
	return rand(at, n_shots)
end

# ╔═╡ 8df7ef80-9363-4f01-9f02-7d4d1082e7ff
md"
## Exercise

Compare the performance of the naive and alias table functions for:

- a statevector of 5 particles, for 10 and 10_000 shots
- a statevector of 20 particles, for 10 and 10_000 shots

What do you notice?
"

# ╔═╡ c0d9d09b-b7b8-437d-8de7-b7ff3c8d51c8
md"
## Advanced exercises

Some common circuits we can test performance with are those that prepare [GHZ](https://en.wikipedia.org/wiki/Greenberger%E2%80%93Horne%E2%80%93Zeilinger_state), or \"cat\" states, and [Quantum Fourier Transforms](https://en.wikipedia.org/wiki/Quantum_Fourier_transform). \"Cat\" states are named after Schroedinger's cat, and are either \"all 0\" or \"all 1\",

```math
\ket{\psi_{GHZ}} = \frac{1}{\sqrt{2}}\ket{00\ldots00} + \frac{1}{\sqrt{2}}\ket{11\ldots11}
```

A circuit to prepare this state vector is:
```julia
ghz_ops = [H(0)] # apply Hadamard to qubit 0
for ii in 0:num_qubits-2
    push!(ghz_ops, CNot(ii, ii+1))
end
```

This uses the `CNot` gate introduced above.

The quantum Fourier transform can be implemented as:

```julia
qft_ops = []
for target_qubit = 0:qubit_count-1 
    angle = π / 2 
    push!(qft_ops, H(target_qubit)) # apply Hadamard to target_qubit
    for control_qubit = target_qubit+1:qubit_count-1 
        push!(qft_ops, CPhaseShift(angle, control_qubit, target_qubit)) 
        angle /= 2 
    end
end
```
And then applying all the operations to an initial state vector. The `CPhaseShift` gate is new to us, and takes an angle argument. Its form is:

```math
\mathtt{CPhaseShift}(\theta) = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & \exp(i\theta) \end{bmatrix}
```

Can you implement and apply each of these circuits to relatively large (26+ qubits) states in an efficient way, using the code we developed above?

It might also be interesting to examine your state vector after each gate (unitary) application to understand what each application actually does -- for GHZ especially, this shows how you can prepare the cat state iteratively.

**Tip**: for the GHZ state, we should start with a $\ket{\psi} = \ket{0\ldots0}$ which can be represented in memory as $[1, 0, 0, \ldots, 0]$ (only the first element is non-zero).
"

# ╔═╡ d51cbc39-b060-4f8e-aec9-df7a48c4be8f
md"
## Summary

In this notebook we covered
- Basics of applying unitaries and computing expectation values
- Basics of sampling a statevector to simulate real execution
- Performance enhancements to each

These techniques are the basics of simulating quantum systems on classical computers, and learning how to do so efficiently will help us write classical code to understand how well quantum hardware is working and benchmark its performance.
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AliasTables = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
Chairmarks = "0ca39b1e-fe0b-4e98-acfc-b1656634c4de"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[compat]
AliasTables = "~1.1.3"
Chairmarks = "~1.3.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.6"
manifest_format = "2.0"
project_hash = "66a0700b983966cac6999dd64aa992c09e67f053"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Chairmarks]]
deps = ["Printf", "Random"]
git-tree-sha1 = "9a49491e67e7a4d6f885c43d00bb101e6e5a434b"
uuid = "0ca39b1e-fe0b-4e98-acfc-b1656634c4de"
version = "1.3.1"

    [deps.Chairmarks.extensions]
    StatisticsChairmarksExt = ["Statistics"]

    [deps.Chairmarks.weakdeps]
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╟─b3c619ca-657c-11f0-31b8-7db9d45d291d
# ╟─9ae17620-14a3-4578-ad60-0ea60665c6eb
# ╟─50fd912f-72cf-47da-ac9d-8144f1c64bc0
# ╟─0e75d215-358a-4871-aeb7-43f2ec78eed9
# ╠═835e5f0f-44a7-4b47-b439-802224b6f915
# ╟─c2f21849-9670-444b-b848-ca5030c094ba
# ╠═44cc8818-fbea-4acd-bbc1-f75fe40d2bed
# ╟─e93eb661-234d-49ad-bb61-c09847ca4f33
# ╠═79412f33-0846-4bcf-b44d-e2cb3dd195b8
# ╠═39004e33-9030-4adb-8655-f65858ad9bd2
# ╠═d39ec526-ae5b-4773-b8d9-3ac3d1e426ec
# ╠═553cf3e5-640e-43ba-baff-e84fb6370c9f
# ╟─213c4ea8-00a4-4e4a-9999-0246fceed042
# ╠═c9fd46bc-7e59-4b68-9b07-b2fe348d267c
# ╠═358c25bb-757d-42bb-aff0-ed659ab4f689
# ╠═2d143124-266f-4b1a-a6b6-67286b0d2ec4
# ╟─4f53e0ce-1aae-44e5-91b2-6f8a5079f627
# ╠═0965928d-91d5-429e-b73b-f447a0207c59
# ╠═602e3a8d-7387-4ad7-9e3c-03ecf4cde890
# ╟─ecc91b02-36fd-4762-9551-93b47a7cc384
# ╠═6006aedd-c173-4bc2-b776-f0161f0199f4
# ╠═8b522aaf-1b97-4972-9e8c-8bd604828d80
# ╠═d0491da7-3734-4728-a7eb-3572debad1c7
# ╠═35658174-1bf3-42ff-b309-878fbcf03cc4
# ╠═088b6487-91e8-442b-8df1-ec5aefeb03da
# ╠═74841f09-a1e4-4dbd-ad4b-1014d72321a9
# ╟─14a1600e-aeb5-412e-9c39-81a6fa8abf3b
# ╠═f8d6d601-7737-48f2-9054-69d97b694423
# ╟─53f5bdd3-660f-4e6b-9c78-67cf379a4f6d
# ╠═08726f6b-3f47-49c3-b7a3-3e55e4209a22
# ╟─e58924e6-7fd6-41d2-9c48-dd839a5c7977
# ╠═b132f748-5af0-4e9e-96f3-ee9f68450f8a
# ╠═00cd7d24-abb8-44d3-93e2-c522d1d75cb4
# ╟─46f5da23-eebf-4166-8d91-0399a4050854
# ╠═b9f25bb9-0aeb-48c5-9050-60b712e355ee
# ╠═effe8ef7-700b-45c6-a4a8-0348e4831dc4
# ╟─60e7ca36-c3e8-444f-86f9-046382557d68
# ╟─c1c6207d-8761-451c-9d1c-3670f5682a76
# ╟─095b6f2f-a772-40c7-8555-f76a4eb65899
# ╠═ceaf7754-69a3-4586-9140-2d001b18cbf2
# ╠═34122d1c-e568-4006-95c2-8fa764596d61
# ╟─140ef143-c2b6-45e0-a2bd-8d207437f66f
# ╟─119b5fc0-ea60-4dbf-9395-36bff547c9c2
# ╠═a953d052-bf60-47b7-90f4-5688d27e8700
# ╟─9ef8e621-e762-400d-8346-bc4077f872c9
# ╟─eb043f42-baca-4f7d-b456-de77e43b97dc
# ╠═570df816-54af-4bc5-83ee-ee3028ef407d
# ╟─59d71c88-0428-4302-88ab-8867be5f299c
# ╠═ad7c7071-8fe5-4182-b156-acd0754dad40
# ╠═5825456c-e279-4597-b265-816557495b52
# ╟─ec03a598-c8d3-4163-9995-4aaa47bffaa5
# ╠═3f7a9f08-d9e0-4940-8737-88fbdd4b02c8
# ╟─21096cfe-57d4-4a4c-8e81-550bb36b88f1
# ╟─dbaf48ed-35f0-4772-85ff-932b093ca40c
# ╟─cdc1adce-3fbe-41f0-ad11-c2c7975b456e
# ╠═4eea53a1-58ff-46ce-98e1-6176e4aabd8e
# ╠═bff46783-0df4-4b46-af26-f92c61f50b35
# ╠═bc58a3c6-e250-48a6-ae4c-aa489cf40a4a
# ╠═48a289f2-7ff0-47b7-838d-cf0191cf2fde
# ╠═458fae9e-ad9e-4e38-875d-675386e1daef
# ╟─40803b98-a790-47df-813f-a558f6d6cfec
# ╠═5c23c8e9-fb96-4f66-b23a-67ab458abaed
# ╠═d1f90185-220a-4443-b2ee-96e1b3963ebb
# ╠═6fc672f7-e72c-4060-a2a5-7a2f047f844c
# ╟─41701c5f-6f7c-4c8f-95a4-b75f6512cb04
# ╠═37796048-3de0-40e7-b7aa-e76612e96b84
# ╠═4a65b30f-3db8-4a5f-b126-99d3a7c7431a
# ╟─d3d8c758-25a5-4187-a736-119ae66ab6b5
# ╠═67b858fe-c936-4eba-bab8-33eb992368c2
# ╠═18335cf9-0168-4e70-8206-8adeda8d9f20
# ╠═e6ced8f2-5c8a-459b-a5fb-4dd665d7c007
# ╠═cbc9cee3-ed2c-402f-b2f5-2f75e02c7c89
# ╠═df786bec-af6c-4d1e-8d31-a94b54c6e8e2
# ╟─82b37a98-fdd5-4575-aa1e-4256e274084a
# ╟─f6f1e2b6-c2bc-49e6-923a-caa4cfe39ab2
# ╟─c2f32fdd-4594-445b-b0ea-e9cdefd38516
# ╠═4c5756b5-4dad-4c77-8266-df8c5b313604
# ╠═fd6fa261-146e-4892-9ee5-4b21bf25568d
# ╠═fb843ec4-9f39-49b8-90a5-09bf37a8290c
# ╠═e5e3e24c-1f3a-4990-87e7-7461c30f16d4
# ╠═7a1afc7d-bfa4-4714-bd8e-ade53910712d
# ╠═6e3e6ae1-f03d-4a3c-9162-583223f30f02
# ╟─28143f2b-a14a-436e-baa8-d2817308b7b0
# ╠═c2161781-92d9-4610-990e-15fb5bec5e11
# ╠═70e59ec9-6a22-4946-8191-7ead62f94c0a
# ╠═41f86858-fed6-49ae-b363-c6e4f7eba516
# ╟─cb9668cc-26e3-43e4-8309-13849dd0f422
# ╟─09af0ec2-b9b1-4c2f-8319-91f8bcafa989
# ╠═4823cc83-caf9-4afc-95da-868f2dfc95c2
# ╟─5506ccf5-c89e-4b1b-9a3f-e1c3df9c9464
# ╠═c963ec08-f353-45fb-8bbb-9b5480a47f98
# ╠═adcd9a23-5197-4439-a19c-b968dcab4f76
# ╟─fdb0a830-e33d-4391-a61d-9959348e40c7
# ╠═725d85e0-331d-4241-bc8d-68849654925d
# ╟─11180e99-04f6-4051-bb58-ef93278037d5
# ╠═13b791c4-68bb-47c9-9464-09f500e16eb0
# ╠═3fcfe42e-407d-4e38-b215-3db76d3a3815
# ╟─1077c26d-a266-4da2-b80c-ee44c6596be3
# ╠═4c7bb461-90c5-4f61-81dd-92326f084a10
# ╠═040d94cc-4d0b-4cda-8a91-6794dbd5f3f6
# ╟─c143c0ac-4f27-471c-876e-5472e4addea3
# ╠═18edcf29-a3b8-4422-a5f0-afc1e58cc013
# ╠═20335f3e-16e8-47ff-abca-37f251771be7
# ╠═9f650edc-835d-4a78-9c50-c38d15e4b7d8
# ╠═5bc1beb8-8cf0-4d68-b8fd-2cd91429b86c
# ╠═bea8e5ba-55f9-4665-a8fa-3bb2dbcf87b6
# ╠═179c9b82-f5ed-4528-aa27-915f695e5824
# ╟─8e8c54e3-2d76-49ed-994a-55f77432c892
# ╠═af3a39ae-4951-4fd4-96aa-9bcf396c548b
# ╟─8fbb3671-2860-4004-a8eb-7e4464dfb4d3
# ╠═6177482d-5078-4137-8045-dd0f08f06e92
# ╠═34734787-a4c0-42f1-94cb-d58a25ed29c8
# ╠═0514ec20-7d2e-4a89-af75-4b710ccdba21
# ╠═39f46cef-070f-4acb-b431-0c7f68fbb78d
# ╟─0404b97e-9452-438d-bdbc-6dd658e73f91
# ╠═fc653ce9-228b-41b6-acdf-e3b90d060179
# ╠═e047212d-9841-4528-9bcb-e3e3fdbfdb7f
# ╠═c63b7710-7c6f-4e0c-b51c-5c9a6a628af4
# ╟─42f468cf-ae6a-432c-8b27-b3d28681d38f
# ╟─b756efcf-5ccb-49c7-8aa7-f2e646b21f5a
# ╟─aa267bc2-c39f-487b-9f69-2c4a3d6ed9f4
# ╠═6024d6e2-316b-4daa-ae4b-3ad9e3824b7c
# ╟─ac6f11ac-1acb-46d1-9b69-0b76380455db
# ╠═1dcffec3-d7a8-4db8-a8e1-5a7e56e04ac9
# ╠═3579848e-2d11-4ae0-b1eb-f49879d3e948
# ╟─5a483683-2e30-49e8-8021-6d733a170230
# ╟─7eeca498-bd3b-47b9-a2b7-3ab097f5da0b
# ╠═c6e0f54a-c6df-457e-8219-397afb328e57
# ╟─226d2765-80b4-45dd-90b6-673e6ccfeed6
# ╠═6aefb4c8-495c-46fe-9ebf-0ec1cf8d8734
# ╟─b523f793-4e9f-4b39-a103-e3b21f9430c9
# ╠═65d54cce-f2bf-4c4b-88a3-e54aa45e22a9
# ╠═12df9728-3431-4f11-b374-f1a943461697
# ╠═d8ecd47b-57e7-4dc1-96dd-66566dd962be
# ╠═bc8d3f18-9c17-4d96-8330-d018a0074c4f
# ╠═dcf2b57b-23ef-4cf0-bce5-f78ef34d3fe8
# ╠═1e90828d-de25-4916-9236-dc5f8e09a495
# ╠═0421c1f8-25b9-4e87-9bbb-4141e070cbeb
# ╟─8fdd3532-0ded-4d6c-aece-fb8a85eed1c8
# ╠═2181672f-21b9-4da4-b5cb-a298494b8dc2
# ╟─8eb5fc73-dfc4-44cb-9b97-d48dfdfafbf0
# ╟─3609f6c7-90f8-4a4e-9cc2-275ffcb7fd30
# ╠═15f83daa-718c-40d4-8acb-8a70453bbbb8
# ╟─d350febc-1950-4cc2-9d66-a4951b8d50a6
# ╟─a32288b0-06f3-478b-9416-03468ed27f25
# ╠═ee5e6301-817b-40e7-930f-4c436d2d0a7b
# ╠═ab6259c2-098b-4bcb-bffc-c9038b2952da
# ╟─8df7ef80-9363-4f01-9f02-7d4d1082e7ff
# ╟─c0d9d09b-b7b8-437d-8de7-b7ff3c8d51c8
# ╟─d51cbc39-b060-4f8e-aec9-df7a48c4be8f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
