module Client = {
  @genType @genType.opaque
  type t

  @module("react-query") @new
  external make: unit => t = "QueryClient"

  module Provider = {
    @module("react-query") @react.component
    external make: (~client: t, ~children: React.element) => React.element = "QueryClientProvider"
  }

  @module("react-query") external useQueryClient: unit => t = "useQueryClient"

  @send
  external invalidateQueries: (t, 'queryKey) => unit = "invalidateQueries"

  @ocaml.doc("Unlike `invalidateQueries`, `setQueryData` matches by exact query keys only.") @send
  external setQueryData: (t, 'queryKey, option<'data> => 'data) => unit = "setQueryData"

  @send
  external clear: t => unit = "clear"
}

type status = [#idle | #loading | #error | #success]

type queryFunctionContext<'queryKey> = {queryKey: 'queryKey}

type queryFn<'queryKey, 'data> = queryFunctionContext<'queryKey> => Js.Promise.t<'data>

module RefetchOnWindowFocus: {
  type t
  let true_: t
  let false_: t
  let always: t
} = {
  type t

  external unsafeT: 'a => t = "%identity"

  let true_: t = unsafeT(true)
  let false_: t = unsafeT(false)
  let always: t = unsafeT("always")
}

type queryOptions<'queryKey, 'data> = {
  queryKey: 'queryKey,
  queryFn: queryFn<'queryKey, 'data>,
  enabled: option<bool>,
  onSuccess: option<'data => unit>,
  keepPreviousData: option<bool>,
  refetchOnWindowFocus: option<RefetchOnWindowFocus.t>,
}

type queryResult<'data> = {
  data: option<'data>,
  status: status,
  error: Js.Null.t<Js.Exn.t>,
  isFetching: bool,
  isStale: bool,
}

@module("react-query")
external useQuery: queryOptions<'queryKey, 'data> => queryResult<'data> = "useQuery"

@module("react-query")
external useQueries: array<queryOptions<'queryKey, 'data>> => array<queryResult<'data>> =
  "useQueries"

type mutationOptions<'mutationKey, 'variables, 'data> = {
  mutationKey: option<'mutationKey>,
  onSuccess: option<('data, 'variables) => option<Js.Promise.t<unit>>>,
  onError: option<(Js.Exn.t, 'variables) => unit>,
}

type mutationResult<'variables, 'data> = {
  data: option<'data>,
  status: status,
  isLoading: bool,
  error: Js.Null.t<Js.Exn.t>,
  mutate: (. 'variables) => unit,
}

@module("react-query")
external useMutation: (
  'variables => Js.Promise.t<'data>,
  mutationOptions<'mutationKey, 'variables, 'data>,
) => mutationResult<'variables, 'data> = "useMutation"

@set external setCancel: (Js.Promise.t<_>, unit => unit) => unit = "cancel"
