[%bs.raw {|require('./ConversationTrasher.css')|}];

open Utils;

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationTrasher");

let make = (~conversation, ~onTrash, _children) => {
  ...component,
  render: _self =>
    <div className="ConversationTrasher">
      {if (conversation.is_in_trash) {
         <span className="btn" onClick={onTrash(conversation, false)}>
           <i className="icon-undo" />
           {textEl("Wiederherstellen")}
         </span>;
       } else {
         <span
           className="btn"
           onClick={onTrash(conversation, !conversation.is_in_trash)}>
           <i className="icon-trash" />
           {textEl({js|Löschen|js})}
         </span>;
       }}
    </div>,
};