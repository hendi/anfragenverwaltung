/* %%raw(`import './ConversationListItem.css'`) */

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
      conversation.is_in_trash ? "bg-purple-100" : bgColor,
      selected ? "selected" : "",
      !conversation.is_read ? "unread" : "",
    ]->Js.Array2.joinWith(" ")}
    >
    <div className="flex w-full justify-between">
      <div className="">
        <input
          className="toggle"
          type_="checkbox"
          checked=selected
          onChange={_evt => onToggleSelect(conversation)}
        />
        <span className="font-bold text-base pointer">
          {conversation.name->React.string}
        </span>
      </div>
      <div className="pull-right">
        <ConversationRater conversation onRating />
        {if (
          /* if (! conversation.is_read) {
                    <i className="icon-asterisk" title="Ungelesen" />;
                } else */
          conversation.is_replied_to
        ) {
          <i className="icon-reply" title="Beantwortet" />
        } else {
          React.null
        }}
        {if conversation.has_attachments {
          <i className="icon-paperclip" title="Dateianhang vorhanden" />
        } else {
          React.null
        }}
        {if String.length(conversation.notes) > 0 {
          <i className="icon-comment-alt" title="Notizen vorhanden" />
        } else {
          React.null
        }}
      </div>
    </div>
    <div className="info">
      <div className="inline-block mt-1 text-xs">
        <IsoDate date={Js.Date.fromString(conversation.date_last_message)} />
        {" um "->React.string}
        <IsoTime date={Js.Date.fromString(conversation.date_last_message)} />
      </div>
    </div>
    <div>
      <div>
        {if conversation.latest_message.message_type == Outgoing {
          <em>
            {"Ihre Antwort: "->React.string}
            {conversation.latest_message.content->max_length(20, 200)->React.string}
          </em>
        } else {
          <span> {conversation.latest_message.content->max_length(20, 200)->React.string} </span>
        }}
      </div>
    </div>
  </div>
}
