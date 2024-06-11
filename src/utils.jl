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
    l = a.length
    nl = l + unsafe_UInt8(NV)
    @inbounds cv = convert(T,vals[NV])
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(i->(i<=L ? (@inbounds d[i]) : i < NL ? (@inbounds convert(T,vals[i-L])) : cv),Val{N_MAX}()),nl)
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
    l = a.length
    nl = l + UInt8(NV)
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(i->(i<=NV ? (@inbounds convert(T,vals[i])) : (@inbounds d[i-NV])),Val{N_MAX}()),nl)
end

"""
    insert(a::ImmutableVector{N}, index::Integer, item) -> ImmutableVector{N}


Returns a `ImmutableVector` with an `item` inserted into `a` at the given `index`. `index` is the index of `item` in the resulting `ImmutableVector`.

See also: [`push`](@ref), [`pushfirst`](@ref), popat.

# Examples
```julia-repl
julia> a = ImmutableVector((2.0,3.0,4.0,5.0,6.0,6.0,6.0),5)
5-element ImmutableVector{7, Float64}:
 2.0
 3.0
 4.0
 5.0
 6.0

julia> b = insert(a,3,0.0)
6-element ImmutableVector{7, Float64}:
 2.0
 3.0
 0.0
 4.0
 5.0
 6.0

```
"""
@inline function insert(a::ImmutableVector{N,T},index::Integer,item) where {N,T}
    @boundscheck checkbounds(a,index)
    NL = length(a) + 1
    d = a.data
    @boundscheck NL > N && throw(BoundsError(d,NL))
    citem = convert(T,item)
    f = @inline function (i)
        i < index ? (@inbounds d[i]) : i == index ? citem : (@inbounds d[i-1])
    end
    return @inbounds ImmutableVector{N,T}(ntuple(f,Val{N}()),a.length+0x01)
end
