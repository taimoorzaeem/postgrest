## PGRST DEV LOG

### This log hold potential issues and ideas that can be worked on

- Add a dedicated Cache.hs module to centralise all cache logic

- Add parser cache for already cached queries (QueryParams) search issue with idea, related issue #2816

- work on docs

- work on documenting internals such as InspectPlan and InfoPlan and Action

- #3424, IO tests depend too heavily on timing / sleeping

- #2895, needs to be closed because, no recovery for fatal errors

Reading/triaging issue (continue here): https://github.com/PostgREST/postgrest/issues?page=5

-- #4023
If instead of `JWT_DURATION`, we use:
```py
random.randint(1,JWT_DURATION)
```
With its `JWT_DURATION = 60`, tThat would give us at most 60-120 different JWTs. Would that be enough?


## Static build with template haskell

hsie is currently pinned to GHC 9.4, nixpkgs will eventually drop the support so migratting it to GHC 9.6 or higher is needed.
Ref: https://github.com/PostgREST/postgrest/pull/4193

##  IO Tests flakiness

Look into IO test-jwt-errors flakiness

The actual root cause of flakiness was that we were executing the
get time action too early in the request processing pipeline. We still hasn't done anything about it, we only adjusted our tests.

## Lazy Data Structures vs Strictness

We are using the many Lazy DataStructures for which performance
could be improved using Strict

-  Lazy -> We don't evaluate unless needed which saves time but takes memory
-  Strict -> We evaluate immediately but waste time when evaluation wasn't needed, but it saves space, so idk


## Refactor ApiRequest

Basically, every request should have it's own Constructor and Record fields,
something like:

data ApiRequest
  = GETReq { ... :: Headers }
  | POSTReq { ... :: _ }
