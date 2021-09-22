open Utils

open MomentRe

@react.component
let make = (~date: Js.Date.t) => {
    <span>
        {textEl(date |> momentWithDate |> Moment.locale("de") |> Moment.format("HH:mm"))}
    </span>
}
