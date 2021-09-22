// This file was automatically converted to ReScript from 'ConversationReadStatus.re'
// Check the output and make sure to delete the original file
%raw(`require('./ConversationReadStatus.css')`)

open Utils

open ConversationData

@react.component
let make = (~conversation, ~onReadStatus) => {
  <div className="ConversationReadStatus">
    {if conversation.is_read && !conversation.is_in_trash {
      <span
        className="btn" onClick={onReadStatus(conversation, false)} title="Als ungelesen markieren">
        <i className="icon-check" /> {textEl("Gelesen")}
      </span>
    } else {
      <span
        className="btn" onClick={onReadStatus(conversation, true)} title="Als gelesen markieren">
        <i className="icon-check-empty" /> {textEl("Gelesen")}
      </span>
    }}
  </div>
}
