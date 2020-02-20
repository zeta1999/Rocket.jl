export tap
export @CreateTapOperator

import Base: show

"""
    tap(tapFn::F) where { F <: Function }

Creates a tap operator, which performs a side effect
for every emission on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tapFn::Function`: side-effect tap function with `(data) -> Nothing` signature

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> tap((d) -> println("In tap: \$d")), logger())
;

# output

In tap: 1
[LogActor] Data: 1
In tap: 2
[LogActor] Data: 2
In tap: 3
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
tap(tapFn::F) where { F <: Function } = TapOperator{F}(tapFn)

struct TapOperator{F} <: InferableOperator
    tapFn::F
end

operator_right(operator::TapOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::TapOperator{F}, source) where { L, F }
    return proxy(L, source, TapProxy{L, F}(operator.tapFn))
end

struct TapProxy{L, F} <: ActorProxy
    tapFn :: F
end

actor_proxy!(proxy::TapProxy{L, F}, actor::A) where { L, A, F } = TapActor{L, A, F}(proxy.tapFn, actor)

struct TapActor{L, A, F} <: Actor{L}
    tapFn :: F
    actor :: A
end

is_exhausted(actor::TapActor) = is_exhausted(actor.actor)

function on_next!(t::TapActor{L}, data::L) where L
    Base.invokelatest(t.tapFn, data)
    next!(t.actor, data)
end

on_error!(t::TapActor, err) = error!(t.actor, err)
on_complete!(t::TapActor)   = complete!(t.actor)

Base.show(io::IO, operator::TapOperator)         = print(io, "TapOperator()")
Base.show(io::IO, proxy::TapProxy{L})    where L = print(io, "TapProxy($L)")
Base.show(io::IO, actor::TapActor{L})    where L = print(io, "TapActor($L)")
