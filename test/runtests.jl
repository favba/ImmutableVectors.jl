using ImmutableVectors
using Test

@testset "ImmutableVectors.jl" begin

    @test_throws DomainError ImmutableVector(ntuple(identity,Val{256}()),256)
    @test_throws DomainError ImmutableVector{5}((1,0,2,3,5,5,5))
    @test_throws DimensionMismatch ImmutableVector{3}([-1,2,3,5])

    @test typeof(ImmutableVector((1.,2.,3.,4.,5.,5.,5.,5.),5)) === ImmutableVector{8,Float64}

    @test collect(ImmutableVector((1.,2.,3.,4.,5.,5.,5.,5.),5)) == [1., 2., 3., 4., 5.]

    a = ImmutableVector((1.,2.,3.,4.,5.,5.,5.,5.),5)

    @test ImmutableVector{8}([1.0,2.0,3.0,4.0,5.0]) === a
    @test convert(ImmutableVector{8,Float64},[1,2,3,4,5]) === a
    @test ImmutableVector{3}(2) === ImmutableVector{3,Int}((2,2,2),1)
    @test ImmutableVector{3}(2,1) === ImmutableVector{3,Int}((2,1,1),2)
    @test ImmutableVector{5,Float64}(0,1,0,3) === ImmutableVector{5,Float64}((0.0, 1.0, 0.0, 3.0, 3.0),4)
    @test ImmutableVector{8}((1,2,3,4,5),3) === ImmutableVector((1,2,3,3,3,3,3,3),3)

    @test length(a) === 5
    @test size(a) === (5,)

    @test max_length(a) == 8
    @test max_length(typeof(a)) == 8


    @test_throws BoundsError getindex(a,6) 

    @test a[3] === 3.0
    @test a[2:5] === ImmutableVector{8}((2.,3.,4.,5.))
    @test a[1:2:5] === ImmutableVector{8}((1.,3.,5.))
    @test a[5:-1:1] === ImmutableVector{8}((5.,4.,3.,2.,1.))

    @test Base.setindex(a,0,3) == ImmutableVector{8}((1.,2.,0.,4.,5.))
    @test Base.setindex(a,0,5) == ImmutableVector((1.,2.,3.,4.,0.,0.,0.,0.),5)

    @test map(-,a) === ImmutableVector((-1.,-2.,-3.,-4.,-5.,-5.,-5.,-5.),5)
    @test map(+,a,a) === ImmutableVector((2.,4.,6.,8.,10.,10.,10.,10.),5)
    @test map(-,a,(1,2,3,4)) === ImmutableVector((0.0,0.0,0.0,0.0))
    @test map(-,(1,2,3,4),a) === ImmutableVector((0.0,0.0,0.0,0.0))
    @test map(sqrt,ImmutableVector{6,Int}(1,2,3,4)) === ImmutableVector{6,Float64}(sqrt(1),sqrt(2),sqrt(3),sqrt(4))

    @test circshift(a,1) == ImmutableVector{8}([5.0,1.0,2.0,3.0,4.0])
    @test circshift(a,-1) == ImmutableVector{8}([2.0,3.0,4.0,5.0,1.0])
    @test circshift(a,4) == ImmutableVector{8}([2.0,3.0,4.0,5.0,1.0])
    @test circshift(a,-4) == ImmutableVector{8}([5.0,1.0,2.0,3.0,4.0])
    @test circshift(a,5) == a
    @test circshift(a,-5) == a
    @test circshift(a,25) == a
    @test circshift(a,-10) == a
    @test circshift(a,7) == circshift(a,2)
    @test circshift(a,-7) == circshift(a,-2)

    @test push(a,6) == ImmutableVector((1.,2.,3.,4.,5.,6.,6.,6.),6)
    @test push(a,6,4) == ImmutableVector((1.,2.,3.,4.,5.,6.,4.,4.),7)
    @test_throws BoundsError push(a,1,1,1,1)

    @test push(ImmutableVector{3,Float64}(),2) === ImmutableVector((2.0,2.0,2.0),0x01)

    @test pushfirst(a,6) == ImmutableVector((6.,1.,2.,3.,4.,5.,5.,5.),6)
    @test pushfirst(a,6,4) == ImmutableVector((6.,4.,1.,2.,3.,4.,5.,5.),7)
    @test_throws BoundsError pushfirst(a,1,1,1,1)

    @test insert(a,3,0) == [1.0, 2.0, 0.0, 3.0, 4.0, 5.0]

    @test sqrt.(a) == map(sqrt, a)
    @test (sqrt.(a) .+ a .^ 2) == map(x -> (sqrt(x) + x^2), a)
end
