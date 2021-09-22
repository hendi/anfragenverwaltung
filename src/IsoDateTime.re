open Utils;

let component = ReasonReact.statelessComponent("IsoDateTime");

let make = (~date: Js.Date.t, _children) => {
  ...component,
  render: _self =>
    <span> <IsoDate date /> (textEl(", ")) <IsoTime date /> </span>
};
