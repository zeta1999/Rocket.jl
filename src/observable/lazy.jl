export LazyObservable, lazy, set!

import Base: show

# TODO: Untested and undocumented

struct LazyObservable{D} <: Subscribable{D}
    pending :: PendingSubjectInstance{ Any, Subject{Any,AsapScheduler,AsapScheduler} }
end

function LazyObservable(::Type{T}, pending) where T
    return LazyObservable{T}(pending)
end

set!(lazy::LazyObservable, observable::S) where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribableTrait,       observable) where D                = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::SimpleSubscribableTrait{D2},    observable) where { D1, D2 <: D1 } = _on_lazy_set!(lazy, observable)
on_lazy_set!(lazy::LazyObservable{D1}, ::ScheduledSubscribableTrait{D2}, observable) where { D1, D2 <: D1 } = _on_lazy_set!(lazy, observable)

function _on_lazy_set!(lazy, observable)
    next!(lazy.pending, observable)
    complete!(lazy.pending)
    return nothing
end

function on_subscribe!(observable::LazyObservable{D}, actor) where D
    return subscribe!(observable.pending |> switch_map(D), actor)
end

lazy(::Type{T} = Any) where T = LazyObservable(T, PendingSubject(Any))

Base.show(io::IO, ::LazyObservable{D}) where D = print(io, "LazyObservable($D)")
