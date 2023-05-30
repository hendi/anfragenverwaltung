/* %%raw(`import './Conversation.css'`) */

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
        <span>
          <i className="icon-undo mr-1" />
          {"Wiederherstellen"->React.string}
        </span>
      } else {
        <span>
          <i className="icon-trash mr-1" />
          {`Löschen`->React.string}
        </span>
      }}
    </button>
  }
}

type action =
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
    | ToggleNotes => ReactUpdate.Update({...state, show_notes: !state.show_notes})
    | NotesChanged(notes) => ReactUpdate.Update({...state, notes})
    }
  , initialState)

  <div
    className={Array.joinWith(
      [
        "flex flex-col h-full",
        conversation.is_in_trash ? "is_in_trash" : "",
      ],
      " ",
    )}>
    <div>
      <div className={Array.joinWith([
        "flex flex-row items-center justify-between py-2",
        switch conversation.rating {
        | Green => "bg-gradient-to-b from-green-100 to-slate-50"
        | Yellow => "bg-gradient-to-b from-yellow-100 to-slate-50"
        | Red => "bg-gradient-to-b from-red-100 to-slate-50"
        | Unrated => ""
        },
      ],
      " ",)}
      >
        <h2 className="text-xl font-semibold"> {conversation.name->React.string} </h2>
        <div className="flex flex-row gap-2 cursor-pointer">
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
      </div>
      
      <div className="space-x-2">
        <span>
          <strong> {"E-Mail: "->React.string} </strong>
          {conversation.email->React.string}
        </span>
        {switch conversation.phone {
        | Some("") => React.null
        | Some(phone) =>
          <span>
            <strong> {"Telefon: "->React.string} </strong>
            {phone->React.string}
          </span>
        | None => React.null
        }}
        {switch (conversation.street, conversation.zipcode, conversation.city) {
        | (Some(""), Some(""), _) => React.null
        | (Some(""), Some(zipcode), Some(city)) =>
          <span>
            <strong> {"Adresse: "->React.string} </strong>
            {`${zipcode} ${city}`->React.string}
          </span>
        | (Some(street), Some(zipcode), Some(city)) =>
          <span>
            <strong> {"Adresse: "->React.string} </strong>
            {`${street}, ${zipcode} ${city})`->React.string}
          </span>
        | _ => React.null
        }}
        <span>
          <strong> {"Via: "->React.string} </strong>
          {conversation.source->React.string}
        </span>
        {if String.length(state.notes) > 0 {
          <div className="hidden-unless-print">
            <strong> {"Private Notizen: "->React.string} </strong>
            <p className="nl2br"> {state.notes->React.string} </p>
          </div>
        } else {
          React.null
        }}
      </div>
      <div className="notes hidden-on-print">
        <a onClick={_event => send(ToggleNotes)}>
          <i className={state.show_notes ? "icon-caret-down" : "icon-caret-right"} />
          {if String.length(state.notes) > 0 || String.length(conversation.notes) > 0 {
            <strong> {"Private Notizen"->React.string} </strong>
          } else {
            "Private Notizen"->React.string
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
                {"Notizen speichern"->React.string}
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
    // main area
    <div className="overflow-y-auto" ref={ReactDOM.Ref.domRef(scrollableRef)}>
      <div className="space-y-3 mb-12">
        {if loading {
          <p> {"Nachrichten werden geladen..."->React.string} </p>
        } else {
          messages
          ->Js.Array2.map((message: message) =>
            <MessageItem key={string_of_int(message.id)} message />
          )
          ->React.array
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
