%%raw(`import './Conversation.css'`)

open Utils

open ConversationData

type state = {
  show_notes: bool,
  notes: string,
}

module TrashButton = {
  @react.component
  let make = (~onClick, ~isInTrash: bool) => {
    <button className="ConversationTrasher" onClick>
      {if isInTrash {
        <span className="btn"> <i className="icon-undo" /> {textEl("Wiederherstellen")} </span>
      } else {
        <span className="btn"> <i className="icon-trash" /> {textEl(`Löschen`)} </span>
      }}
    </button>
  }
}
module Reply = {
  type t = {
    conversation: conversation,
    messageText: string,
    attachments: array<string>,
  }
}

type action =
  | LoadingMessages
  | LoadedMessages(array<message>)
  | ReplySent(message)
  | ToggleNotes
  | NotesChanged(string)

let scrollElementToTop: Dom.element => int = %raw(`
function (domNode) {
  domNode.scrollTop = 99999999;
  return 0;
}
`)

@react.component
let make = (
  ~conversation: conversation,
  ~onReplySend: (conversation, string, array<string>) => unit,
  ~onRating,
  ~onTrash,
  ~onReadStatus: (conversation, bool) => unit,
  ~onIgnore: unit => unit,
  ~onSaveNotes,
  ~onBack as _,
  ~messages: array<message>,
  ~loading: bool,
) => {
  let scrollableRef = React.useRef(Js.Nullable.null)
  let initialState = {
    show_notes: false,
    notes: conversation.notes,
  }

  let scrollUp = () =>
    switch scrollableRef.current->Js.Nullable.toOption {
    | Some(domNode) => scrollElementToTop(domNode)->ignore
    | None => ()
    }

  //TODO: Scroll to top when a reply has been sent
  let (state, send) = ReactUpdate.useReducer((state, action) =>
    switch action {
    | ReplySent(_reply) =>
      ReactUpdate.UpdateWithSideEffects(
        state,
        /* TODO
             {
               ...state,
               messages: Array.make(1, reply) |> Array.append(state.messages),
             },*/
        _self => {
          switch scrollableRef.current->Js.Nullable.toOption {
          | Some(domNode) => scrollElementToTop(domNode)->ignore
          | None => ()
          }
          None
        },
      )
    | ToggleNotes => ReactUpdate.Update({...state, show_notes: !state.show_notes})
    | NotesChanged(notes) => ReactUpdate.Update({...state, notes: notes})
    | LoadedMessages(_)
    | LoadingMessages =>
      ReactUpdate.NoUpdate
    }
  , initialState)


  <div
    className={list{
      "Conversation",
      switch conversation.rating {
      | Green => "rating-green"
      | Yellow => "rating-yellow"
      | Red => "rating-red"
      | Unrated => "rating-unrated"
      },
      conversation.is_in_trash ? "is_in_trash" : "",
    } |> String.concat(" ")}>
    <div className="header">
      <div className="pull-right" style={ReactDOM.Style.make(~paddingTop="2px", ())}>
        <ConversationPrinter conversation />
        <ConversationReadStatus conversation onReadStatus />
        <TrashButton
          isInTrash={conversation.is_in_trash}
          onClick={_evt => {
            onTrash(conversation, !conversation.is_in_trash)
          }}
        />
        <ConversationRater conversation onRating />
      </div>
      <h2> {textEl(conversation.name)} </h2>
      <span> <strong> {textEl("E-Mail: ")} </strong> {textEl(conversation.email)} </span>
      {switch conversation.phone {
      | Some("") => React.null
      | Some(phone) => <span> <strong> {textEl("Telefon: ")} </strong> {textEl(phone)} </span>
      | None => React.null
      }}
      {switch (conversation.street, conversation.zipcode, conversation.city) {
      | (Some(""), Some(""), _) => React.null
      | (Some(""), Some(zipcode), Some(city)) =>
        <span> <strong> {textEl("Adresse: ")} </strong> {textEl(zipcode ++ (" " ++ city))} </span>
      | (Some(street), Some(zipcode), Some(city)) =>
        <span>
          <strong> {textEl("Adresse: ")} </strong>
          {textEl(street ++ (", " ++ (zipcode ++ (" " ++ city))))}
        </span>
      | _ => React.null
      }}
      <span> <strong> {textEl("Via: ")} </strong> {textEl(conversation.source)} </span>
      {if String.length(state.notes) > 0 {
        <div className="hidden-unless-print">
          <strong> {textEl("Private Notizen: ")} </strong>
          <p className="nl2br"> {textEl(state.notes)} </p>
        </div>
      } else {
        React.null
      }}
      <div className="notes hidden-on-print">
        <a onClick={_event => send(ToggleNotes)}>
          <i className={state.show_notes ? "icon-caret-down" : "icon-caret-right"} />
          {if String.length(state.notes) > 0 || String.length(conversation.notes) > 0 {
            <strong> {textEl("Private Notizen")} </strong>
          } else {
            textEl("Private Notizen")
          }}
        </a>
        {if state.show_notes {
          <div>
            <textarea
              value=state.notes
              onChange={event => send(NotesChanged((event->ReactEvent.Form.target)["value"]))}
            />
            {if state.notes != conversation.notes {
              <button
                className="btn btn-primary"
                onClick={_event => onSaveNotes(conversation, state.notes)}
                disabled={state.notes == conversation.notes}>
                {textEl("Notizen speichern")}
              </button>
            } else {
              React.null
            }}
          </div>
        } else {
          React.null
        }}
      </div>
    </div>
    <div className="main scrollable" ref={ReactDOM.Ref.domRef(scrollableRef)}>
      <div>
        {if loading {
          <p> {textEl("Nachrichten werden geladen...")} </p>
        } else {
          messages
          |> Array.map((message: message) =>
            <MessageItem key={string_of_int(message.id)} message />
          )
          |> arrayEl
        }}
      </div>
      {if !conversation.is_in_trash {
        <ReplyEditor
          key={Belt.Int.toString(conversation.id)}
          conversation
          onReplySend={(conversation, msg, attachments) => {
            onReplySend(conversation, msg, attachments)
            scrollUp()
          }}
          onIgnoreConversation={_event => onIgnore()}
        />
      } else {
        React.null
      }}
    </div>
  </div>
}
