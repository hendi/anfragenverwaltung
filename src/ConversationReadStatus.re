[%bs.raw {|require('./ConversationReadStatus.css')|}];

open Utils;

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationReadStatus");

let make = (~conversation, ~onReadStatus, _children) => {
  ...component,
  render: _self =>
    <div className="ConversationReadStatus">
      {if (conversation.is_read && !conversation.is_in_trash) {
         <span
           className="btn"
           onClick={onReadStatus(conversation, false)}
           title="Als ungelesen markieren">
           <i className="icon-check" />
           {textEl("Gelesen")}
         </span>;
       } else {
         <span
           className="btn"
           onClick={onReadStatus(conversation, true)}
           title="Als gelesen markieren">
           <i className="icon-check-empty" />
           {textEl("Gelesen")}
         </span>;
       }}
    </div>,
};