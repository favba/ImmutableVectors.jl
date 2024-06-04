module ImmutableVectors

export ImmutableVector
export max_length, push, pushfirst

struct ImmutableVector{MAX_N,T} <: AbstractVector{T}
    data::NTuple{MAX_N,T}
    length::UInt8
    
    @inline function ImmutableVector{N_MAX,T}(data::NTuple{N_MAX,T},length::Number) where {N_MAX,T}
        N_MAX <= 255 || throw(DomainError(N_MAX,"Maximum Tuple size supported is 255"))
        length <= N_MAX || throw(DomainError(length,"Vector length must be equal to or smaller than Tuple length ($N_MAX)"))
        if length != N_MAX
            let v = data[length]
                all(isequal(v),Iterators.drop(data,length)) || throw(DomainError(data,"Tuple must be padded with the vectors last element `data[length] = $(data[length])`"))
            end
        end
        return new{N_MAX,T}(data,UInt8(length))
    end
end

@inline function ImmutableVector(data::NTuple{N,T},length=N) where {N,T}
    return ImmutableVector{N,T}(data,length)
end

@inline function ImmutableVector{N_MAX}(data::NTuple{N,T},length=N) where {N_MAX,N,T}
    N > N_MAX && throw(DomainError(data))
    N == N_MAX && return ImmutableVector(data,length)
    last_data = data[length]
    return ImmutableVector{N_MAX,T}(ntuple(i->(i < length ? data[i] : last_data),Val(N_MAX)),length)
end

@inline function ImmutableVector{N_MAX}(v::AbstractVector{T}) where {N_MAX,T}
    l = length(v)
    l <= N_MAX || throw(DimensionMismatch("Vector length is larger than maximum specified length"))
    last_v = v[l]
    return ImmutableVector{N_MAX,T}(ntuple(i->(i < l ? v[i] : last_v),Val{N_MAX}()),l)
end

@inline ImmutableVector{N_MAX}(v::T) where {N_MAX,T} = ImmutableVector{N_MAX,T}(ntuple(i->v,Val{N_MAX}()),UInt8(1))

@inline Base.length(d::ImmutableVector) = Int(d.length)
@inline Base.size(d::ImmutableVector) = (length(d),)

@inline function Base.getindex(d::ImmutableVector,i::Integer)
    @boundscheck checkbounds(d,i)
    data = d.data
    return @inbounds data[i]
end

@inline function Base.getindex(a::ImmutableVector{N,T},I::AbstractVector) where {N,T}
    @boundscheck checkbounds(a,I)
    l = length(I)
    d = a.data
    last_v = @inbounds d[I[end]]
    return ImmutableVector{N,T}(ntuple((i-> i<l ? (@inbounds d[I[i]]) : last_v),Val{N}()),l)
end

@inline max_length(::ImmutableVector{N,T}) where {N,T} = N
@inline max_length(::Type{<:ImmutableVector{N,T}}) where {N,T} = N

include("base_methods.jl")
include("utils.jl")

end
