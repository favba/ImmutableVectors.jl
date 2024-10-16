"""
    ImmutableVectorArray{NT, T, N} <: AbstractArray{ImmutableVector{NT, T}, N}

An array of `ImmutableVector`s that follows a SoA layout ("Struct of Arrays") for the `ImmutableVector`'s `data` and `length` fields
"""
struct ImmutableVectorArray{N_MAX, T, N, TD <: AbstractArray{NTuple{N_MAX,T},N}} <: AbstractArray{ImmutableVector{N_MAX, T}, N}
    data::TD
    length::Array{UInt8, N}

    function ImmutableVectorArray(data::AbstractArray{NTuple{N_MAX,T},N}, l::Array{UInt8, N}) where {N_MAX, T, N}
        size(l) == size(data) || throw(DimensionMismatch())
        return new{N_MAX, T, N, typeof(data)}(data, l)
    end
end

const ImVecArray{N_MAX, T, N} = ImmutableVectorArray{N_MAX, T, N, Array{NTuple{N_MAX, T}, N}}

ImmutableVectorArray(data::AbstractArray{NTuple{N_MAX,T}, N}, l::AbstractArray{<:Integer,N}) where {N_MAX, T, N} = ImmutableVectorArray(data, UInt8.(l))

ImmutableVectorArray{N_MAX, T}(s::Vararg{Integer}) where {N_MAX, T} = ImmutableVectorArray(Array{NTuple{N_MAX, T}}(undef, s...), zeros(UInt8, s...))

ImVecArray{N_MAX, T}(s::Vararg{Integer}) where {N_MAX, T} = ImmutableVectorArray{N_MAX, T}(s...)

Base.size(IVA::ImmutableVectorArray) = size(IVA.data)
Base.length(IVA::ImmutableVectorArray) = length(IVA.data)
Base.IndexStyle(::Type{ImmutableVectorArray{NN, T, N, TD}}) where {NN, T, N, TD} = IndexStyle(TD)
Base.similar(a::ImmutableVectorArray, dims=size(a)) = ImmutableVectorArray(similar(a.data, dims), similar(a.length, dims))

@inline function Base.getindex(a::ImmutableVectorArray, i::Integer)
    @boundscheck checkbounds(a,i)
    data = a.data
    l = a.length
    @inbounds ImmutableVector(data[i], l[i])
end

@inline function Base.setindex!(a::ImmutableVectorArray, v, i::Integer)
    @boundscheck checkbounds(a,i)
    cv = convert(eltype(a), v)
    data = a.data
    l = a.length
    @inbounds data[i] = cv.data
    @inbounds l[i] = cv.length
    return a
end

@inline function Base.getindex(a::ImmutableVectorArray{NN, T, N}, I::Vararg{Integer}) where {NN, T, N}
    @boundscheck checkbounds(a,I...)
    data = a.data
    l = a.length
    @inbounds ImmutableVector(data[I...], l[I...])
end

@inline function Base.setindex!(a::ImmutableVectorArray{NN, T, N}, v, I::Vararg{Integer}) where {NN, T, N}
    @boundscheck checkbounds(a,I...)
    cv = convert(eltype(a), v)
    data = a.data
    l = a.length
    @inbounds data[I...] = cv.data
    @inbounds l[I...] = cv.length
    return a
end

