"""
    push(vector::ImmutableVector{N}, items...) -> ImmutableVector{N}

If `length(vector) + length(items) <= N` returns a new `ImmutableVector{N}` with the `items` appended to the elements of `vector` (in the given order).

See also [`pushfirst`](@ref)

# Examples
```julia-repl
julia> a = ImmutableVector{5}(1)
1-element ImmutableVector{5, Int64}:
 1

julia> push(a,2,3)
3-element ImmutableVector{5, Int64}:
 1
 2
 3
```
"""
@inline function push(a::ImmutableVector{N_MAX,T},vals::Vararg{Any,NV}) where {N_MAX,T,NV}
    L = length(a)
    NL = L + NV
    d = a.data
    @boundscheck NL > N_MAX && throw(BoundsError(d,NL)) 
    cvals = map(x->convert(T,x),vals)
    l = a.length
    nl = l + unsafe_UInt8(NV)
    @inbounds cv = cvals[end]
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(i->(i<=L ? (@inbounds d[i]) : i < NL ? (@inbounds cvals[i-L]) : cv),Val{N_MAX}()),nl)
end

"""
    pushfirst(vector::ImmutableVector{N}, items...) -> ImmutableVector{N}

If `length(vector) + length(items) <= N` returns a new `ImmutableVector{N}` with the `items` prepended to the elements of `vector` (in the given order).

See also [`push`](@ref)

# Examples
```julia-repl
julia> a = ImmutableVector{5}(1)
1-element ImmutableVector{5, Int64}:
 1

julia> pushfirst(a,-1,0)
3-element ImmutableVector{5, Int64}:
 -1
  0
  1
```
"""
@inline function pushfirst(a::ImmutableVector{N_MAX,T},vals::Vararg{Any,NV}) where {N_MAX,T,NV}
    L = length(a)
    NL = L + NV
    d = a.data
    @boundscheck NL > N_MAX && throw(BoundsError(d,NL)) 
    cvals = map(x->convert(T,x),vals)
    l = a.length
    nl = l + UInt8(NV)
    @inbounds cv = d[L]
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(i->(i<=NV ? (@inbounds cvals[i]) : i < NL ? (@inbounds d[i-NV]) : cv),Val{N_MAX}()),nl)
end
