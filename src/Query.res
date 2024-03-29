type resource = [#conversation | #message]

type t<'data> =
  | Idle
  | Loading
  | Success('data)
  | Error(Js.Exn.t)

module RefetchOnWindowFocus = {
  type t = YesIfStale | Never | Always

  let toReactQueryOption = refetchOnWindowFocus =>
    switch refetchOnWindowFocus {
    | Always => ReactQuery.RefetchOnWindowFocus.always
    | Never => ReactQuery.RefetchOnWindowFocus.false_
    | YesIfStale => ReactQuery.RefetchOnWindowFocus.true_
    }
}

let useQuery = (
  ~enabled=?,
  ~refetchOnWindowFocus=RefetchOnWindowFocus.Never,
  ~resource: resource,
  ~params: 'params,
  queryFn,
) => {
  let {data, status, error, _} = ReactQuery.useQuery({
    queryKey: (resource, params),
    queryFn: ({queryKey: (_, parameters)}) => queryFn(parameters),
    enabled: enabled,
    onSuccess: None,
    keepPreviousData: None,
    refetchOnWindowFocus: refetchOnWindowFocus->RefetchOnWindowFocus.toReactQueryOption->Some,
  })

  switch status {
  | #idle => Idle
  | #loading => Loading
  | #success => Success(Belt.Option.getUnsafe(data))
  | #error => Error(Js.Null.getUnsafe(error))
  }
}

let useDependentQuery = (
  ~resource: resource,
  ~refetchOnWindowFocus=RefetchOnWindowFocus.Never,
  ~params: option<'params>,
  queryFn: 'promise => Js.Promise.t<'ret>,
): t<'ret> => {
  let {data, status, error, _} = ReactQuery.useQuery({
    queryKey: (resource, params),
    queryFn: ({queryKey: (_, params)}) =>
      switch params {
      | None =>
        Js.Exn.raiseError(
          "This should not execute if `params === None`. This may be a bug in React Query, or in our understanding of it.",
        )
      | Some(params) => queryFn(params)
      },
    enabled: params->Belt.Option.isSome->Some,
    onSuccess: None,
    keepPreviousData: None,
    refetchOnWindowFocus: refetchOnWindowFocus->RefetchOnWindowFocus.toReactQueryOption->Some,
  })

  switch status {
  | #idle => Idle
  | #loading => Loading
  | #success => Success(Belt.Option.getUnsafe(data))
  | #error => Error(Js.Null.getUnsafe(error))
  }
}

let useMutation = (
  ~mutationKey: option<'key>=?,
  ~onSuccess: option<('ret, 'params, 'context) => option<Js.Promise.t<unit>>>=?,
  ~onError: option<('err, 'params, 'context) => unit>=?,
  ~onSettled: option<('data, Js.Exn.t, 'variables, 'context) => unit>=?,
  ~onMutate: option<'params => Js.Promise.t<'context>>=?,
  mutationFn: 'params => Js.Promise.t<'ret>,
) => {
  let {data, status, error, mutate, isLoading: _} = ReactQuery.useMutation(
    mutationFn,
    {
      mutationKey: mutationKey,
      onSuccess: onSuccess,
      onError: onError,
      onSettled: onSettled,
      onMutate: onMutate,
    },
  )

  (
    switch status {
    | #idle => Idle
    | #loading => Loading
    | #success => Success(Belt.Option.getUnsafe(data))
    | #error => Error(Js.Null.getUnsafe(error))
    },
    mutate,
  )
}
