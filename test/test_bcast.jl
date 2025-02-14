include("common.jl")
using Random

MPI.Init()

comm = MPI.COMM_WORLD
root = 0
matsize = (17,17)

for T in MPITestTypes
    # This test depends on the stability of the rng and we have observed with
    # CUDA.jl that it is not gurantueed that the same number of rand calls will
    # occur on each rank. (This is a hypothesis). To be sure we shall seed the rng
    # just before we call rand.
    Random.seed!(17)
    A = ArrayType(rand(T, matsize))
    B = MPI.Comm_rank(comm) == root ? A : similar(A)
    MPI.Bcast!(B, comm; root=root)
    @test B == A
end

# Char
A = ['s', 't', 'a', 'r', ' ', 'w', 'a', 'r', 's']
B = MPI.Comm_rank(comm) == root ? A : similar(A)
MPI.Bcast!(B, comm; root=root)
@test B == A


# Bcast: number
A = 1.23
B = MPI.Comm_rank(comm) == root ? 1.23 : 0.0
res = MPI.Bcast(B, root, comm)
@test typeof(res) == typeof(A)
@test res == A

# Bcast: scalar struct
struct XY
    x::Float64
    y::Float32
end
A = XY(1.23, 4.56f0)
B = MPI.Comm_rank(comm) == root ? A : XY(0.0, 0.0f0)
res = MPI.Bcast(B, root, comm)
@test typeof(res) == typeof(A)
@test res == A

# Bcast: array
A = rand(3)
B = MPI.Comm_rank(comm) == root ? A : zeros(3)
@test_throws ArgumentError MPI.Bcast(B, root, comm)

g = x -> x^2 + 2x - 1
if MPI.Comm_rank(comm) == root
    f = g
else
    f = nothing
end
f = MPI.bcast(f, root, comm)
@test f(3) == g(3)
@test f(5) == g(5)
@test f(7) == g(7)


A = Dict("foo" => "bar")
if MPI.Comm_rank(comm) == root
    B = A
else
    B = nothing
end
B = MPI.bcast(B, root, comm)
@test B["foo"] == "bar"

MPI.Finalize()
@test MPI.Finalized()
