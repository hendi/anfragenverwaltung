%%raw(`import './Conversation.css'`)

open Utils

open ConversationData

type state = {
  show_notes: bool,
  notes: string,
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
  | SendReply(Reply.t)
  | ReplySent(message)
  | IgnoreConversation
  | ToggleNotes
  | NotesChanged(string)
  | SaveNotes

let scrollElementToTop: Dom.element => int = %raw(`
function (domNode) {
  domNode.scrollTop = 99999999;
  return 0;
}
`)

@react.component
let make = (
  ~conversation: conversation,
  ~onReplySent: message => unit,
  ~onRating,
  ~onTrash,
  ~onReadStatus: (conversation, bool) => unit,
  ~onIgnore,
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

  let (state, send) = ReactUpdate.useReducer((state, action) =>
    switch action {
    | SendReply(reply) =>
      ReactUpdate.UpdateWithSideEffects(
        state,
        _self => {
          postReply(reply.conversation, reply.messageText, reply.attachments, msg => {
            Js.log2("test", msg)
            onReplySent(msg)
          })
          None
        },
      )
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
    | IgnoreConversation => ReactUpdate.NoUpdate
    | ToggleNotes => ReactUpdate.Update({...state, show_notes: !state.show_notes})
    | NotesChanged(notes) => ReactUpdate.Update({...state, notes: notes})
    | SaveNotes =>
      ReactUpdate.UpdateWithSideEffects(
        state,
        _self => {
          onSaveNotes(conversation, state.notes)
          None
        },
      )
    | LoadedMessages(_)
    | LoadingMessages =>
      ReactUpdate.NoUpdate
    }
  , initialState)

  let onReplySend = (conversation: conversation, messageText, attachments) => {
    SendReply({
      Reply.conversation: conversation,
      messageText: messageText,
      attachments: attachments,
    })->send
  }

  let ignoreConversation = (conversation: conversation) => {
    send(IgnoreConversation)
    onIgnore(conversation)
  }

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
        <ConversationTrasher conversation onTrash />
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
                onClick={_event => send(SaveNotes)}
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
          onReplySend
          onIgnoreConversation={_event => ignoreConversation(conversation)}
        />
      } else {
        React.null
      }}
    </div>
  </div>
}
