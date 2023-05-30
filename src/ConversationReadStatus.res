/*%%raw(`import './ConversationReadStatus.css'`)*/

open ConversationData

@react.component
let make = (~conversation, ~onReadStatus: (conversation, bool) => unit) => {
  let onClick = evt => {
    ReactEvent.Mouse.preventDefault(evt)
    onReadStatus(conversation, !conversation.is_read)
  }

  <div className="ConversationReadStatus">
    {if conversation.is_read && !conversation.is_in_trash {
      <span className="btn" onClick title="Als ungelesen markieren">
        <i className="icon-check" /> {"Gelesen"->React.string}
      </span>
    } else {
      <span className="btn" onClick title="Als gelesen markieren">
        <i className="icon-check-empty" /> {"Gelesen"->React.string}
      </span>
    }}
  </div>
}
