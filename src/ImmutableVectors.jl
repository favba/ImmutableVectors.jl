module ImmutableVectors

export ImmutableVector
export max_length, push, pushfirst, insert, padwith
export ImmutableVectorArray, ImVecArray

@inline unsafe_UInt8(x::Integer) = Base.Core.Intrinsics.trunc_int(UInt8, x)
@inline unsafe_UInt8(x::UInt8) = x

"""
    ImmutableVector{N_MAX, T} <: AbstractVector{T}

An immutable vector of `T` elements with variable length (up to `N_MAX`) that uses the same memmory layout regardless of it's length, therefore producing efficient memmory layout for arrays of such elements.

# Fields

- `data::NTuple{MAX_N, T}`: Tuple holding the vector data, together with possible padding elements.

- `length::UInt8`: Vector length (Maximum allowed of `MAX_N`)

"""
struct ImmutableVector{MAX_N, T} <: AbstractVector{T}
    data::NTuple{MAX_N, T}
    length::UInt8

    @inline function ImmutableVector{N_MAX, T}(data::NTuple{N_MAX, T}, length::Integer) where {N_MAX, T}
        N_MAX <= 255 || throw(DomainError(N_MAX, "Maximum Tuple size supported is 255"))
        @boundscheck 0 <= length <= N_MAX || throw(DomainError(length, "Vector length must be equal to or smaller than Tuple length ($N_MAX)"))
        return new{N_MAX, T}(data, unsafe_UInt8(length))
    end
end

@inline function ImmutableVector(data::NTuple{N, T}) where {N, T}
    return @inbounds ImmutableVector{N, T}(data, UInt8(N))
end

Base.@propagate_inbounds function ImmutableVector(data::NTuple{N, T}, length::Integer) where {N, T}
    return ImmutableVector{N, T}(data, length)
end

@inline function ImmutableVector{N_MAX, T}(v1, vals::Vararg{Any, N}) where {N_MAX, N, T}
    N + 1 <= N_MAX || throw(DomainError(N + 1, "Number of input values is greater than maximum supported size of $N_MAX"))
    cv1 = convert(T, v1)
    cvlast = @inbounds convert(T, vals[N])
    f = @inline function (i)
        i == 1 && return cv1
        ii = i - 1
        return ii < N ? convert(T, @inbounds vals[ii]) : cvlast
    end
    @inbounds ImmutableVector{N_MAX, T}(ntuple(f, Val{N_MAX}()), UInt8(N + 1))
end

@inline function ImmutableVector{N_MAX, T}(v1, vals::Vararg{Any, 0}) where {N_MAX, T}
    cv1 = convert(T, v1)
    return @inbounds ImmutableVector{N_MAX, T}(ntuple(i -> cv1, Val{N_MAX}()), 0x01)
end

@inline ImmutableVector{N_MAX}(v1::T, vals::Vararg{T, N}) where {N_MAX, N, T} = ImmutableVector{N_MAX, T}(v1, vals...)

default_initializer(::Type{T}) where {T} = zero(T)
@inline ImmutableVector{N_MAX, T}() where {N_MAX, T} = @inbounds ImmutableVector{N_MAX, T}(ntuple(i -> default_initializer(T), Val{N_MAX}()), 0x00)

@inline ImmutableVector{N_MAX}(data::NTuple{N, T}) where {N_MAX, N, T} = ImmutableVector{N_MAX}(data...)

Base.@propagate_inbounds function ImmutableVector{N_MAX}(data::NTuple{N, T}, length::Integer) where {N_MAX, N, T}
    N > N_MAX && throw(DomainError(data))
    N == N_MAX && return ImmutableVector(data, length)
    @boundscheck 0 <= length <= N || throw(DomainError(length, "Vector length must be equal to or smaller than $N"))
    last_d = @inbounds data[length]
    f = @inline function (i)
        i < length ? (@inbounds data[i]) : last_d
    end
    return @inbounds ImmutableVector{N_MAX, T}(ntuple(f, Val(N_MAX)), unsafe_UInt8(length))
end

@inline function ImmutableVector{N_MAX, T1}(v::AbstractVector{T}) where {N_MAX, T1, T}
    l = length(v)
    l <= N_MAX || throw(DimensionMismatch("Input length ($l) is larger than maximum allowed ($N_MAX)"))
    f = @inline function (i)
        ii = min(l, i)
        @inbounds convert(T1, v[ii])
    end
    return @inbounds ImmutableVector{N_MAX, T1}(ntuple(f, Val{N_MAX}()), unsafe_UInt8(l))
end

@inline ImmutableVector{N_MAX}(v::AbstractVector{T}) where {N_MAX, T} = ImmutableVector{N_MAX, T}(v)

Base.convert(::Type{ImmutableVector{N_MAX, T}}, v::AbstractVector) where {N_MAX, T} = ImmutableVector{N_MAX, T}(v)

@inline function _convert_smaller(::Type{ImmutableVector{N, T}}, v::ImmutableVector{N2, T2}) where {N, T, N2, T2}
    data = v.data
    return @inbounds ImmutableVector{N,T}(ntuple(@inline(i->convert(T,@inbounds(data[min(N2,i)]))), Val{N}()), v.length)
end

@generated function Base.convert(t::Type{ImmutableVector{N, T}}, v::ImmutableVector{N2, T2}) where {N, T, N2, T2}
    if N == N2 && T === T2
        quote
            $(Expr(:meta, :inline))
            return v
        end
    elseif N2 <= N
        quote
            $(Expr(:meta, :inline))
            return _convert_smaller(t,v)
        end
    else
        quote
            $(Expr(:meta, :inline))
            return ImmutableVector{$N, $T}(v)
        end
    end
end

@inline Base.length(d::ImmutableVector) = Int(d.length)
@inline Base.size(d::ImmutableVector) = (length(d),)

@inline function Base.getindex(d::ImmutableVector, i::Integer)
    @boundscheck checkbounds(d, i)
    data = d.data
    return @inbounds data[i]
end

@inline function Base.getindex(a::ImmutableVector{N, T}, I::AbstractVector) where {N, T}
    @boundscheck checkbounds(a, I)
    l = length(I)
    d = a.data
    last_v = @inbounds d[I[end]]
    return @inbounds ImmutableVector{N, T}(ntuple((i -> i < l ? (@inbounds d[I[i]]) : last_v), Val{N}()), unsafe_UInt8(l))
end

@inline max_length(::ImmutableVector{N, T}) where {N, T} = N
@inline max_length(::Type{<:ImmutableVector{N, T}}) where {N, T} = N

include("broadcast.jl")
include("base_methods.jl")
include("utils.jl")
include("struct_array.jl")
end
