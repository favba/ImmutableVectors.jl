module ImmutableVectors

export ImmutableVector
export max_length, push, pushfirst, insert

@inline unsafe_UInt8(x::Integer) = Base.Core.Intrinsics.trunc_int(UInt8,x)
@inline unsafe_UInt8(x::UInt8) = x

struct ImmutableVector{MAX_N,T} <: AbstractVector{T}
    data::NTuple{MAX_N,T}
    length::UInt8
    
    @inline function ImmutableVector{N_MAX,T}(data::NTuple{N_MAX,T},length::Number) where {N_MAX,T}
        N_MAX <= 255 || throw(DomainError(N_MAX,"Maximum Tuple size supported is 255"))
        @boundscheck length <= N_MAX || throw(DomainError(length,"Vector length must be equal to or smaller than Tuple length ($N_MAX)"))
        return new{N_MAX,T}(data,unsafe_UInt8(length))
    end
end

@inline function ImmutableVector(data::NTuple{N,T}) where {N,T}
    return @inbounds ImmutableVector{N,T}(data,UInt8(N))
end

Base.@propagate_inbounds function ImmutableVector(data::NTuple{N,T},length::Number) where {N,T}
    return ImmutableVector{N,T}(data,length)
end

@inline function ImmutableVector{N_MAX,T}(v1,vals::Vararg{Any,N}) where {N_MAX,N,T}
    N+1 <= N_MAX || throw(DomainError(N+1,"Number of input values is greater than maximum supported size of $N_MAX"))
    cv1 = convert(T,v1)
    f = @inline function (i)
        is_first = i==1
        ii = is_first ? 1 : min(i-1,N)
        return is_first ? cv1 : convert(T,@inbounds vals[ii])
    end
    @inbounds ImmutableVector{N_MAX,T}(ntuple(f,Val{N_MAX}()),UInt8(N+1))
end

@inline function ImmutableVector{N_MAX,T}(v1,vals::Vararg{Any,0}) where {N_MAX,T}
    cv1 = convert(T,v1)
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(i->cv1,Val{N_MAX}()),0x01)
end

@inline ImmutableVector{N_MAX}(v1::T,vals::Vararg{T,N}) where {N_MAX,N,T} = ImmutableVector{N_MAX,T}(v1,vals...)

default_initializer(::Type{T}) where T = zero(T)
@inline ImmutableVector{N_MAX,T}() where {N_MAX,T} = @inbounds ImmutableVector{N_MAX,T}(ntuple(i->default_initializer(T),Val{N_MAX}()),0x00)

@inline ImmutableVector{N_MAX}(data::NTuple{N,T}) where {N_MAX,N,T} = ImmutableVector{N_MAX}(data...)

Base.Base.@propagate_inbounds function ImmutableVector{N_MAX}(data::NTuple{N,T},length::Number) where {N_MAX,N,T}
    N > N_MAX && throw(DomainError(data))
    N == N_MAX && return ImmutableVector(data,length)
    f = @inline function (i)
        ii = min(length,i)
        @inbounds data[ii]
    end
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(f,Val(N_MAX)),unsafe_UInt8(length))
end

@inline function ImmutableVector{N_MAX}(v::AbstractVector{T}) where {N_MAX,T}
    l = length(v)
    l <= N_MAX || throw(DimensionMismatch("Input length ($l) is larger than maximum allowed ($N_MAX)"))
    f = @inline function (i)
        ii = min(l,i)
        @inbounds v[ii]
    end
    return @inbounds ImmutableVector{N_MAX,T}(ntuple(f,Val{N_MAX}()),unsafe_UInt8(l))
end

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
    return @inbounds ImmutableVector{N,T}(ntuple((i-> i<l ? (@inbounds d[I[i]]) : last_v),Val{N}()),unsafe_UInt8(l))
end

@inline max_length(::ImmutableVector{N,T}) where {N,T} = N
@inline max_length(::Type{<:ImmutableVector{N,T}}) where {N,T} = N

include("base_methods.jl")
include("utils.jl")

end
