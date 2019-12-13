module RxTeardownChainTest

using Test

import Rx
import Rx: Teardown, ChainTeardown

@testset "ChainTeardown" begin

    struct DummyUnsubscribable <: Teardown end
    Rx.as_teardown(::Type{<:DummyUnsubscribable}) = Rx.UnsubscribableTeardownLogic()
    Rx.unsubscribe!(::DummyUnsubscribable) = "unsubscribed"

    @test ChainTeardown(DummyUnsubscribable()) isa Teardown
    @test Rx.as_teardown(ChainTeardown) === Rx.UnsubscribableTeardownLogic()
    @test Rx.unsubscribe!(ChainTeardown(DummyUnsubscribable())) === "unsubscribed"

end

end
