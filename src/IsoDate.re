open Utils;

open MomentRe;

let component = ReasonReact.statelessComponent("IsoDate");

let make = (~date: Js.Date.t, _children) => {
  ...component,
  render: _self =>
    <span>
      (
        textEl(
          date
          |> momentWithDate
          |> Moment.locale("de")
          |> Moment.format("DD.MM.YYYY")
        )
      )
    </span>
};
