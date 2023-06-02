open ConversationData

@react.component
let make = (~conversation, ~onReadStatus: (conversation, bool) => unit) => {
  let onClick = evt => {
    ReactEvent.Mouse.preventDefault(evt)
    onReadStatus(conversation, !conversation.is_read)
  }

  <div className="flex flex-col lg:flex-row items-center justify-center bg-slate-50 py-2 lg:py-1 px-2 hover:bg-blue-100 border cursor-pointer w-full lg:w-auto" onClick >
    {if conversation.is_read && !conversation.is_in_trash {
        <i className="icon-check mr-1" /> 
    } else {
        <i className="icon-check-empty mr-1" />
    }}
    {"Gelesen"->React.string}
  </div>
}
