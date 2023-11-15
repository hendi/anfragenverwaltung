open ConversationData

type state = {
  show_notes: bool,
  notes: string,
}

module TrashButton = {
  @react.component
  let make = (~onClick, ~isInTrash: bool) => {
    <div className="flex flex-col lg:flex-row items-center justify-center bg-slate-50 py-2 lg:py-1 px-2 hover:bg-blue-100 lg:border border-y border-r cursor-pointer w-full lg:w-auto" onClick>
      {if isInTrash {
          <i className="icon-undo mr-1" />
      } else {
          <i className="icon-trash mr-1" />
      }}
      {isInTrash ? {"Wiederherstellen"->React.string} : {`Löschen`->React.string}}
    </div>
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
  ~messages: array<message>,
  ~loading: bool,
  ~isMobile: bool,
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

  let highlightGradient = if conversation.is_in_trash {
    "bg-gradient-to-b from-gray-300 to-slate-50"
  } else {
    switch conversation.rating {
    | Green => "bg-gradient-to-b from-emerald-300 to-slate-50"
    | Yellow => "bg-gradient-to-b from-yellow-200 to-slate-50"
    | Red => "bg-gradient-to-b from-red-300 to-slate-50"
    | Unrated => ""
    }
  }

  <div
    className={Array.joinWith(
      [
        "flex flex-col h-full",
        conversation.is_in_trash ? "text-gray-500 print:text-black" : "",
      ],
      " ",
    )}>
      {if isMobile {
        <div className="flex flex-col">
          <div className="flex flex-row justify-around items-center text-black print:hidden">
            <ConversationPrinter conversation />
            <ConversationReadStatus conversation onReadStatus />
            <TrashButton
              isInTrash={conversation.is_in_trash}
              onClick={_evt => {
                onTrash(conversation, !conversation.is_in_trash)
              }}
            />
          </div>
          <div className={Array.joinWith(["print:hidden",highlightGradient]," ",)}>
           <ConversationRater conversation onRating />
          </div>
          <h2 className="text-xl font-semibold p-2 hidden print:block"> {conversation.name->React.string} </h2>
        </div>
      } else {
        <div className={Array.joinWith([
          "flex flex-row items-center justify-between py-2 px-2 text-black",
          highlightGradient
        ],
        " ",)}
        >
          <h2 className="text-xl font-semibold"> {conversation.name->React.string} </h2>
          <div className="flex flex-row gap-2 cursor-pointer items-center print:hidden">
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
      }}
      
      <div className="flex flex-col lg:block lg:space-x-2 px-2">
        <span>
          <strong> {"E-Mail:\u00A0"->React.string} </strong>
          {conversation.email->React.string}
        </span>
        {switch Js.Nullable.toOption(conversation.phone) {
        | Some(phone) =>
          <span>
            <strong> {"Telefon:\u00A0"->React.string} </strong>
            {phone->React.string}
          </span>
        | None => React.null
        }}
        {switch (Js.Nullable.toOption(conversation.street), Js.Nullable.toOption(conversation.zipcode), Js.Nullable.toOption(conversation.city)) {
        | (None, None, _) => React.null
        | (None, Some(zipcode), Some(city)) =>
          <span>
            <strong> {"Adresse:\u00A0"->React.string} </strong>
            {`${zipcode}\u00A0${city}`->React.string}
          </span>
        | (Some(street), Some(zipcode), Some(city)) =>
          <span>
            <strong> {"Adresse:\u00A0"->React.string} </strong>
            {`${street}, ${zipcode}\u00A0${city}`->React.string}
          </span>
        | _ => React.null
        }}
        <span>
          <strong> {"Via:\u00A0"->React.string} </strong>
          {conversation.source->React.string}
        </span>
        <span>
          {
            switch Js.Nullable.toOption(conversation.shared_profile_link) {
            | Some(link) => 
               <span>
                <strong> {"Profil des Interessenten:\u00A0"->React.string} </strong>
                <a className="text-blue-500 mb-2" target="_blank" href={link}> <i className="icon-user mr-1" />{"Profil anschauen"->React.string} </a>
              </span>
            | _ => React.null
            }
          }
        </span>
      </div>
      {if String.length(state.notes) > 0 {
          <div className="hidden px-2 mb-4 print:block">
            <strong> {"Private Notizen: "->React.string} </strong>
            <p> {state.notes->React.string} </p>
          </div>
        } else {
          React.null
      }}
      <div className="mb-2 px-2 print:hidden">
        <a className={`text-blue-500 cursor-pointer ${String.length(conversation.notes) > 0 ? "font-bold" : ""}`} onClick={_event => send(ToggleNotes)}>
          <i className={state.show_notes ? "icon-caret-down mr-1" : "icon-caret-right mr-1"} />
          {"Private Notizen"->React.string}
        </a>
        {if state.show_notes {
          <div>
            <textarea
              className="w-full rounded p-2 border mb-2"
              rows=4
              value=state.notes
              onChange={event => send(NotesChanged((event->ReactEvent.Form.target)["value"]))}
            />
            {if state.notes != conversation.notes {
              <button
                className="bg-blue-500 hover:bg-blue-400 text-white rounded p-2"
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
    
    // main area
    <div className="overflow-y-scroll h-auto lg:h-screen print:h-full px-2" ref={ReactDOM.Ref.domRef(scrollableRef)}>
      <div className="space-y-3 mb-4">
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
