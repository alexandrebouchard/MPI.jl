"""
    MPI.Group

An MPI Group object.
"""
mutable struct Group
    val::MPI_Group
end
Base.:(==)(a::Group, b::Group) = a.val == b.val
Base.cconvert(::Type{MPI_Group}, group::Group) = group
Base.unsafe_convert(::Type{MPI_Group}, group::Group) = group.val
Base.unsafe_convert(::Type{Ptr{MPI_Group}}, group::Group) = convert(Ptr{MPI_Group}, pointer_from_objref(group))

const GROUP_NULL = Group(API.MPI_GROUP_NULL[])
const GROUP_EMPTY = Group(API.MPI_GROUP_EMPTY[])
add_load_time_hook!(() -> GROUP_NULL.val = API.MPI_GROUP_NULL[])
add_load_time_hook!(() -> GROUP_EMPTY.val = API.MPI_GROUP_EMPTY[])

Group() = Group(GROUP_NULL.val)

# int MPI_Group_range_excl(MPI_Group group, int n, int ranges[][3], MPI_Group *newgroup)
# int MPI_Group_range_incl(MPI_Group group, int n, int ranges[][3], MPI_Group *newgroup)
# int MPI_Group_translate_ranks(MPI_Group group1, int n, const int ranks1[], MPI_Group group2, int ranks2[])

function free(group::Group)
    if group != GROUP_NULL && !Finalized()
        # int MPI_Group_free(MPI_Group *group)
        API.MPI_Group_free(group)
    end
    return nothing
end

"""
    Group_size(group::Group)

The number of processes involved in group.

# External links
$(_doc_external("MPI_Group_size"))
"""
function Group_size(group::Group)
    size = Ref{Cint}()
    API.MPI_Group_size(group, size)
    Int(size[])
end

"""
    Group_rank(group::Group)

The rank of the process in the particular group.

Returns an integer in the range `0:MPI.Group_size()-1`.

# External links
$(_doc_external("MPI_Group_rank"))
"""
function Group_rank(group::Group)
    rank = Ref{Cint}()
    API.MPI_Group_rank(group, rank)
    Int(rank[])
end

"""
    Comparison

An enum denoting the result of [`Comm_compare`](@ref):

 - `MPI.IDENT`: the objects are handles for the same object (identical groups and same contexts).

 - `MPI.CONGRUENT`: the underlying groups are identical in constituents and rank order; these communicators differ only by context.

 - `MPI.SIMILAR`: members of both objects are the same but the rank order differs.

 - `MPI.UNEQUAL`: otherwise
"""
mutable struct Comparison
    val::Cint
end
const IDENT     = Comparison(API.MPI_IDENT[])
const CONGRUENT = Comparison(API.MPI_CONGRUENT[])
const SIMILAR   = Comparison(API.MPI_SIMILAR[])
const UNEQUAL   = Comparison(API.MPI_UNEQUAL[])
add_load_time_hook!(() -> IDENT.val     = API.MPI_IDENT[]    )
add_load_time_hook!(() -> CONGRUENT.val = API.MPI_CONGRUENT[])
add_load_time_hook!(() -> SIMILAR.val   = API.MPI_SIMILAR[]  )
add_load_time_hook!(() -> UNEQUAL.val   = API.MPI_UNEQUAL[]  )
Base.:(==)(tl1::Comparison, tl2::Comparison) = tl1.val == tl2.val

function Group_compare(group1::Group, group2::Group)
    result = Ref{Cint}()
    API.MPI_Group_compare(group1, group2, result)
    return Comparison(result[])
end

function Group_difference(group1::Group, group2::Group)
    newgroup = Group()
    API.MPI_Group_difference(group1, group2, newgroup)
    finalizer(free, newgroup)
    return newgroup
end

function Group_intersection(group1::Group, group2::Group)
    newgroup = Group()
    API.MPI_Group_intersection(group1, group2, newgroup)
    finalizer(free, newgroup)
    return newgroup
end

function Group_union(group1::Group, group2::Group)
    newgroup = Group()
    API.MPI_Group_union(group1, group2, newgroup)
    finalizer(free, newgroup)
    return newgroup
end

function Group_excl(group::Group, ranks::Vector{Cint})
    newgroup = Group()
    API.MPI_Group_excl(group, length(ranks), ranks, newgroup)
    finalizer(free, newgroup)
    return newgroup
end

function Group_incl(group::Group, ranks::Vector{Cint})
    newgroup = Group()
    API.MPI_Group_incl(group, length(ranks), ranks, newgroup)
    finalizer(free, newgroup)
    return newgroup
end
