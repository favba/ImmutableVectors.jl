struct ImmutableVecStyle{N_MAX} <: Broadcast.AbstractArrayStyle{1} end

Base.BroadcastStyle(::Type{<:ImmutableVector{N_MAX}}) where {N_MAX} = ImmutableVecStyle{N_MAX}()

ImmutableVecStyle{N_MAX}(::Val{0}) where {N_MAX} = ImmutableVecStyle{N_MAX}()
ImmutableVecStyle{N_MAX}(::Val{1}) where {N_MAX} = ImmutableVecStyle{N_MAX}()
ImmutableVecStyle{N_MAX}(::Val{N}) where {N_MAX, N} = Broadcast.DefaultArrayStyle{N}()

Base.BroadcastStyle(::Broadcast.Style{Tuple}, a::ImmutableVecStyle{N_MAX}) where {N_MAX} = a
Base.BroadcastStyle(::ImmutableVecStyle{N1}, ::ImmutableVecStyle{N2}) where {N1, N2} = ImmutableVecStyle{max(N1, N2)}()

@inline function Base.copy(bc::Broadcast.Broadcasted{ImmutableVecStyle{N}}) where {N}
    dim = axes(bc)
    length(dim) == 1 || throw(DimensionMismatch("ImmutableVector only supports one dimension"))
    @inbounds L = dim[1][end]
    last_el = getindex(bc, L)
    return @inbounds(ImmutableVector(ntuple(i -> (i < L ? @inbounds(getindex(bc, i)) : last_el), Val(N)), unsafe_UInt8(L)))
end

@inline function Base.copy(bc::Broadcast.Broadcasted{ImmutableVecStyle{N}, T1, T2, T3}) where {T1, T2, N, T3 <: Tuple{Vararg{ImmutableVector{N}}}}
    dim = axes(bc)
    length(dim) == 1 || throw(DimensionMismatch("ImmutableVector only supports one dimension"))
    lengths = length.(bc.args)
    if allequal(lengths)
        return map(bc.f, bc.args...)
    else
        L = maximum(lengths)
        return @inbounds(ImmutableVector(map(bc.f, getfield.(bc.args, (:data,))...), unsafe_UInt8(L)))
    end
end
