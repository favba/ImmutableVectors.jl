struct ImmutableVecStyle{N_MAX} <: Broadcast.AbstractArrayStyle{1} end

Base.BroadcastStyle(::Type{<:ImmutableVector{N_MAX}}) where {N_MAX} = ImmutableVecStyle{N_MAX}()

ImmutableVecStyle{N_MAX}(::Val{0}) where {N_MAX} = ImmutableVecStyle{N_MAX}()
ImmutableVecStyle{N_MAX}(::Val{1}) where {N_MAX} = ImmutableVecStyle{N_MAX}()
ImmutableVecStyle{N_MAX}(::Val{N}) where {N_MAX, N} = Broadcast.DefaultArrayStyle{N}()

Base.BroadcastStyle(::Broadcast.Style{Tuple}, a::ImmutableVecStyle{N_MAX}) where {N_MAX} = a
Base.BroadcastStyle(::ImmutableVecStyle{N1}, ::ImmutableVecStyle{N2}) where {N1, N2} = ImmutableVecStyle{max(N1, N2)}()

@inline function Base.copy(bc::Broadcast.Broadcasted{ImmutableVecStyle{N}}) where {N}
    bcf = @inline Broadcast.flatten(bc)
    dim = axes(bcf)
    length(dim) == 1 || throw(DimensionMismatch("ImmutableVector only supports one dimension"))

    if length(bcf.args) == 1
        return @inline map(bcf.f, bcf.args[1])
    else
        @inbounds L = length(dim[1])
        last_el = @inbounds @inline bcf[L]

        f_tuple = @inline function(i)
            i < L ? @inbounds(@inline bcf[i]) : last_el
        end

        return @inline @inbounds(ImmutableVector(ntuple(f_tuple, Val(N)), unsafe_UInt8(L)))
    end
end
