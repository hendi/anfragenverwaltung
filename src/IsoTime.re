open Utils;

open MomentRe;

let component = ReasonReact.statelessComponent("IsoTime");

let make = (~date: Js.Date.t, _children) => {
  ...component,
  render: _self =>
    <span>
      (
        textEl(
          date
          |> momentWithDate
          |> Moment.locale("de")
          |> Moment.format("HH:mm")
        )
      )
    </span>
};
