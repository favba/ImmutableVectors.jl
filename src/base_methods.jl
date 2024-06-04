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
@inline function Base.setindex(a::ImmutableVector{N_MAX,T},v,i::Integer) where {N_MAX,T}
    @boundscheck checkbounds(a,i)
    cv = convert(T,v)
    l = a.length
    d = a.data
    if (l == N_MAX) || (i != l)
        return ImmutableVector{N_MAX,T}(Base.setindex(d,cv,i),l)
    else
        return ImmutableVector{N_MAX,T}(ntuple(i->(i<l ? d[i] : cv),Val{N_MAX}()),l)
    end
end

function Base.map(f::F,a::ImmutableVector{N1,T1}) where {F<:Function,N1,T1}
    Tf = Base.promote_op(f,T1)
    l = length(a)
    d = a.data
    last_fd = @inbounds f(d[l])
    func = i -> (i < l ? (@inbounds f(d[i])) : last_fd)
    return ImmutableVector{N1,Tf}(ntuple(func,Val{N1}()),a.length)
end

function Base.map(f::F,a::ImmutableVector{N1,T1},b::ImmutableVector{N2,T2}) where {F<:Function,N1,T1,N2,T2}
    Tf = Base.promote_op(f,T1,T2)
    Nf = min(N1,N2)
    l = min(length(a),length(b))
    da = a.data
    db = b.data
    last_fab = @inbounds f(da[l],db[l])
    func = i -> (i < l ? (@inbounds f(da[i], db[i])) : last_fab)
    return ImmutableVector{Nf,Tf}(ntuple(func,Val{Nf}()),UInt(l))
end

Base.map(f,a::Tuple,b::ImmutableVector) = map(f,ImmutableVector(a),b)
Base.map(f,a::ImmutableVector,b::Tuple) = map(f,a,ImmutableVector(b))

function Base.circshift(a::ImmutableVector{N,T},nn::Integer) where {N,T}
    l= length(a)
    n = rem(nn,l) 

    n == 0 && return a

    f = function (i)
        @inline
        j = i-n
        k = j <= 0 ? l + j : j > l ?  rem(j,l) : j
        return @inbounds a[k]
    end
    last_f = f(l)
    return ImmutableVector{N,T}(ntuple(i->(i < l ? f(i) : last_f),Val{N}()),a.length)
end
