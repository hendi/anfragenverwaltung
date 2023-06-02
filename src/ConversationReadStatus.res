open ConversationData

@react.component
let make = (~conversation, ~onReadStatus: (conversation, bool) => unit) => {
  let onClick = evt => {
    ReactEvent.Mouse.preventDefault(evt)
    onReadStatus(conversation, !conversation.is_read)
  }

  <div className="flex justify-center bg-white py-1 px-2 hover:bg-blue-100 border cursor-pointer w-full lg:w-auto">
    {if conversation.is_read && !conversation.is_in_trash {
      <span onClick title="Als ungelesen markieren">
        <i className="icon-check mr-1" /> {"Gelesen"->React.string}
      </span>
    } else {
      <span onClick title="Als gelesen markieren">
        <i className="icon-check-empty mr-1" /> {"Gelesen"->React.string}
      </span>
    }}
  </div>
}
