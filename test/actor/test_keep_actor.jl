module RocketKeepActorTest

using Test
using Rocket

@testset "KeepActor" begin

    println("Testing: actor KeepActor")

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = KeepActor{Int}()

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3 ]
    end

    @testset begin
        source = faulted(Int, "Error")
        actor  = KeepActor{Int}()

        @test_throws ErrorException subscribe!(source, actor)
        @test actor.values == []
    end

    @testset begin
        @test keep(Int) isa KeepActor{Int}
    end
end

end
