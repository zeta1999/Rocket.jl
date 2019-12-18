export max
export MaxOperator, on_call!
export MaxProxy, actor_proxy!
export MaxActor, on_next!, on_error!, on_complete!

import Base: max

"""
    max(; from = nothing)

Creates a max operator, which emits a single item: the item with the largest value.

# Arguments
- `from`: optional initial maximum value, if `nothing` first item from the source will be used as initial instead

# Producing

Stream of type <: Subscribable{Union{L, Nothing}} where L refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> max(), LoggerActor{Union{Int, Nothing}}())
;

# output

[LogActor] Data: 42
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
max(; from = nothing) = MaxOperator(from)

struct MaxOperator <: InferrableOperator
    from
end

function on_call!(::Type{L}, ::Type{Union{L, Nothing}}, operator::MaxOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{Union{L, Nothing}}(source, MaxProxy{L}(operator.from != nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::MaxOperator, ::Type{L}) where L = Union{L, Nothing}

struct MaxProxy{L} <: ActorProxy
    from :: Union{L, Nothing}
end

actor_proxy!(proxy::MaxProxy{L}, actor::A) where { A <: AbstractActor{Union{L, Nothing}} } where L = MaxActor{L, A}(proxy.from, actor)

mutable struct MaxActor{L, A <: AbstractActor{Union{L, Nothing}} } <: Actor{L}
    current :: Union{L, Nothing}
    actor   :: A
end

function on_next!(actor::MaxActor{L, A}, data::L) where { A <: AbstractActor{Union{L, Nothing}} } where L
    if actor.current == nothing
        actor.current = data
    else
        actor.current = data > actor.current ? data : actor.current
    end
end

function on_error!(actor::MaxActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::MaxActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
