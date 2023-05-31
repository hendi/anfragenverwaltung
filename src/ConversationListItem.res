open Utils
open ConversationData

@react.component
let make = (
  ~onClick: option<ReactEvent.Mouse.t => unit>=?,
  ~onRating: (ConversationData.conversation, ConversationData.rating, ReactEvent.Mouse.t) => unit,
  ~onToggleSelect: conversation => unit,
  ~conversation: conversation,
  ~selected: bool,
  ~active: bool,
) => {
  let bgColor = if active {
    "bg-blue-100"
  } else {
    switch conversation.rating {
    | Green => "bg-green-100"
    | Yellow => "bg-yellow-100"
    | Red => "bg-red-100"
    | Unrated => ""
    }
  }

  <div
  ?onClick
  className={[
      "cursor-pointer p-2",
      conversation.is_in_trash ? `text-gray-500 ${active ? "bg-blue-100" : "" }` : bgColor,
      selected ? "selected" : "",
      !conversation.is_read ? "unread" : "",
    ]->Js.Array2.joinWith(" ")}
    >
    <div className="flex w-full justify-between">
      <div className="flex flex-row gap-2 items-center">
        <input
          type_="checkbox"
          checked=selected
          onChange={_ => ()}
          onClick={evt => {
            ReactEvent.Mouse.stopPropagation(evt);
            onToggleSelect(conversation)
          }}
        />
        <span className="font-bold text-base">
          {conversation.name->React.string}
        </span>
      </div>
      <div className="flex flex-row items-center gap-x-1">
        {if (
          conversation.is_replied_to
        ) {
          <i className="icon-reply text-[#236ea2] mr-1" title="Beantwortet" />
        } else {
          React.null
        }}
        {if conversation.has_attachments {
          <i className="icon-paperclip mr-1" title="Dateianhang vorhanden" />
        } else {
          React.null
        }}
        {if String.length(conversation.notes) > 0 {
          <i className="icon-comment-alt mb-1 mr-1" title="Notizen vorhanden" />
        } else {
          React.null
        }}
        <ConversationRater conversation onRating />
      </div>
    </div>
    <div className="flex flex-row">
      <div className="inline-block mt-1 text-xs">
        <IsoDate date={Js.Date.fromString(conversation.date_last_message)} />
        {" um "->React.string}
        <IsoTime date={Js.Date.fromString(conversation.date_last_message)} />
      </div>
    </div>
    <div>
      <div>
        {if conversation.latest_message.type_ == Outgoing {
          <em>
            {"Ihre Antwort: "->React.string}
            {conversation.latest_message.content->maxLength(20, 200)->React.string}
          </em>
        } else {
          <span> {conversation.latest_message.content->maxLength(20, 200)->React.string} </span>
        }}
      </div>
    </div>
  </div>
}
