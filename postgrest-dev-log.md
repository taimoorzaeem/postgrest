## PGRST DEV LOG

### This log hold potential issues and ideas that can be worked on

- Add a dedicated Cache.hs module to centralise all cache logic

- Add parser cache for already cached queries (QueryParams) search issue with idea, related issue #2816

- there is JWT Errors with their own PGRST code

- work on docs

Its hard to work on internals when they are not very well documented

- work on documenting internals such as InspectPlan and InfoPlan and Action

- #3498, improve mediatype parser

- #3424, IO tests depend too heavily on timing / sleeping

- Refactor: the schemacache errors need to be separted from apiRequestError

 - WIP remove content-range with range header
  + https://stackoverflow.com/questions/3715981/what-s-the-best-restful-method-to-return-total-number-of-items-in-an-object
  + https://github.com/PostgREST/postgrest/issues/2776 (content-range)
  + https://github.com/PostgREST/postgrest/issues/2777 (content-range)

Reading/triaging issue (continue here): https://github.com/PostgREST/postgrest/issues?page=5
