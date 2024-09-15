"""
    Base.setindex(x::ImmutableVector, v, i::Integer)


Creates a new ImmutableVector similar to `x` with the value at index `i` set to `v`. Throws a BoundsError when out of bounds.

# Examples

```julia-repl
julia> a = ImmutableVector{5}((1,2,3))
3-element ImmutableVector{5, Int64}:
 1
 2
 3

julia> Base.setindex(a,0,2)
3-element ImmutableVector{5, Int64}:
 1
 0
 3

julia> Base.setindex(a,0,4)
ERROR: BoundsError: attempt to access 3-element ImmutableVector{5, Int64} at index [4]
```

"""
@inline function Base.setindex(a::ImmutableVector{N_MAX, T}, v, i::Integer) where {N_MAX, T}
    @boundscheck checkbounds(a, i)
    cv = convert(T, v)
    l = a.length
    d = a.data
    return @inbounds ImmutableVector{N_MAX, T}(Base.setindex(d, cv, i), l)
end

@inline min_max_length(a::ImmutableVector, b::NTuple{N, ImmutableVector}) where {N} = Val{min(max_length(a), map(max_length, b)...)}()

function Base.map(f::F, a::ImmutableVector, b::Vararg{ImmutableVector}) where {F <: Function}
    Nf = min_max_length(a, b)
    l = min(a.length, (x -> getfield(x, :length)).(b)...)
    L = Int(l)
    db = (a.data, (x -> getfield(x, :data)).(b)...)
    last_f = f((x -> (@inbounds getindex(x, L))).(db)...)
    func = @inline function (i)
        i < L ? (f((x -> (@inbounds getindex(x, i))).(db)...)) : last_f
    end
    return @inbounds ImmutableVector(ntuple(func, Nf), l)
end

Base.map(f, a::Tuple, b::ImmutableVector) = map(f, ImmutableVector(a), b)
Base.map(f, a::ImmutableVector, b::Tuple) = map(f, a, ImmutableVector(b))

function Base.circshift(a::ImmutableVector{N, T}, nn::Integer) where {N, T}
    l = length(a)
    n = rem(nn, l)

    n == 0 && return a
    d = a.data

    f = @inline function (i)
        j = rem(i - n, l)
        k = ifelse(j <= 0, l + j, ifelse(j > l, rem(j, l), j))
        return @inbounds d[k]
    end
    return @inbounds ImmutableVector{N, T}(ntuple(f, Val{N}()), a.length)
end
