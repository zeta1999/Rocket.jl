export BehaviorSubject, BehaviorSubjectFactory
export make_behavior_subject, make_behavior_subject_factory

import Base: show

"""
    BehaviorSubject{D, S}(current, subject)

A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

# Arguments
- `current`: Default current value
- `subject`: Subject base type

See also: [`make_behavior_subject`](@ref), [`make_subject`](@ref)
"""
mutable struct BehaviorSubject{D, S} <: Actor{D}
    current :: D
    subject :: S
end

as_subject(::Type{<:BehaviorSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:BehaviorSubject{D}}) where D = SimpleSubscribableTrait{D}()

is_exhausted(actor::BehaviorSubject) = is_exhausted(actor.subject)

function on_next!(subject::BehaviorSubject{D}, data::D) where D
    subject.current = data
    next!(subject.subject, data)
end

function on_error!(subject::BehaviorSubject, err)
    error!(subject.subject, err)
end

function on_complete!(subject::BehaviorSubject)
    complete!(subject.subject)
end

function on_subscribe!(subject::BehaviorSubject, actor)
    next!(actor, subject.current)
    return subscribe!(subject.subject, actor)
end

# --------------------------------- #
# Behavior subject create operators #
# --------------------------------- #

make_behavior_subject(::Type{T}, current::T, subject_factory::F) where T where { F <: AbstractSubjectFactory } = make_behavior_subject(T, current, create_subject(T, subject_factory))
make_behavior_subject(::Type{T}, current::T, subject::S)         where T where S                               = as_behavior_subject(T, as_subject(S), current, subject)

as_behavior_subject(::Type{T},  ::InvalidSubject,   current,     subject)    where T                   = throw(InvalidSubjectTraitUsageError(subject))
as_behavior_subject(::Type{T1}, ::ValidSubject{T2}, current::T1, subject::S) where T1 where T2 where S = throw(InconsistentSubjectDataTypesError{T1, T2}(subject))
as_behavior_subject(::Type{T},  ::ValidSubject{T},  current::T,  subject::S) where T where S           = BehaviorSubject{T, S}(current, subject)


"""
    make_behavior_subject(::Type{T}, current::T; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M

Creation operator for the `BehaviorSubject`

See also: [`BehaviorSubject`](@ref), [`make_subject`](@ref)
"""
make_behavior_subject(::Type{T}, current::T; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M = make_behavior_subject(T, current, make_subject_factory(mode = mode))

# ------------------------- #
# Behavior subject factory  #
# ------------------------- #

struct BehaviorSubjectFactory{M} <: AbstractSubjectFactory
    default
end

create_subject(::Type{L}, factory::BehaviorSubjectFactory{M}) where L where M = make_behavior_subject(L, convert(L, factory.default); mode = Val(M))

make_behavior_subject_factory(default; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = BehaviorSubjectFactory{M}(default)

Base.show(io::IO, subject::BehaviorSubject{T, S})     where T where S = print(io, "BehaviorSubject($T, $S)")
Base.show(io::IO, subject::BehaviorSubjectFactory{M}) where M         = print(io, "BehaviorSubjectFactory($M)")
