[%bs.raw {|require('./ConversationPrinter.css')|}];

[@bs.scope "window"] [@bs.val] external print: unit => unit = "print";

open ConversationData;
open Utils;

let component = ReasonReact.statelessComponent("ConversationPrinter");

let make = (~conversation: conversation, _children) => {
  ...component,
  render: _self =>
    <div className="ConversationPrinter">
      <span className="btn" onClick={_event => print()}>
        <i className="icon-print" title="Unterhaltung drucken" />
        {textEl("Drucken")}
      </span>
    </div>,
};
