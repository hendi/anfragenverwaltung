// Original: https://github.com/bloodyowl/rescript-react-update/blob/main/src/ReactUpdate.res
@@warning("-30")

type dispatch<'action> = 'action => unit

type rec update<'action, 'state> =
  | NoUpdate
  | Update('state)
  | UpdateWithSideEffects('state, self<'action, 'state> => option<unit => unit>)
  | SideEffects(self<'action, 'state> => option<unit => unit>)
and self<'action, 'state> = {
  send: dispatch<'action>,
  dispatch: dispatch<'action>,
  state: 'state,
}
and fullState<'action, 'state> = {
  state: 'state,
  sideEffects: ref<array<self<'action, 'state> => option<unit => unit>>>,
}

type reducer<'state, 'action> = ('state, 'action) => update<'action, 'state>

let useReducer = (reducer, initialState) => {
  let ({state, sideEffects}, send) = React.useReducer(({state, sideEffects} as fullState, action) =>
    switch reducer(state, action) {
    | NoUpdate => fullState
    | Update(state) => {...fullState, state}
    | UpdateWithSideEffects(state, sideEffect) => {
        state,
        sideEffects: ref(Array.concat(sideEffects.contents, [sideEffect])),
      }
    | SideEffects(sideEffect) => {
        ...fullState,
        sideEffects: ref(Array.concat(fullState.sideEffects.contents, [sideEffect])),
      }
    }
  , {state: initialState, sideEffects: ref([])})
  React.useEffect3(() => {
    if Array.length(sideEffects.contents) > 0 {
      let sideEffectsToRun = Js.Array.sliceFrom(0, sideEffects.contents)
      sideEffects := []
      let cancelFuncs = Belt.Array.keepMap(sideEffectsToRun, func =>
        func({state, send, dispatch: send})
      )
      Array.length(cancelFuncs) > 0 ? Some(() => cancelFuncs->Array.forEach(func => func())) : None
    } else {
      None
    }
  }, (sideEffects, send, state))
  (state, send)
}
