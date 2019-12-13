module RxTest

using Test

@testset "Rx" begin
    include("./test_teardown.jl")
    include("./teardown/test_void_teardown.jl")
    include("./teardown/test_chain_teardown.jl")

    include("./test_actor.jl")
    include("./actor/test_void_actor.jl")
    include("./actor/test_lambda_actor.jl")
    include("./actor/test_logger_actor.jl")

    include("./test_subscribable.jl")
end

end