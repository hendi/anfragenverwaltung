/* %%raw(`import './ConversationList.css'`) */

open Utils

open ConversationData

@react.component
let make = (
  ~folder: Folder.t,
  ~loading: bool,
  ~currentConversation: option<conversation>,
  ~conversations: array<conversation>,
  ~selectedConversations: list<int>,
  ~onConversationClick,
  ~onRating,
  ~onTrash as _,
  ~onReadStatus as _,
  ~onToggleSelect: conversation => unit,
  ~onToggleSelectAll: bool => unit,
  ~onFilterTextChange,
  ~onMassReply,
  ~onMassTrash: unit => unit,
  ~hasAnyConversations,
  ~isFiltered,
) => {
  <div>
    <div>
      {if folder != Trash {
        <div className="flex flex-row justify-around items-center">
          <button className="flex flex-col w-full items-center justify-center hover:bg-blue-200 p-2 hover:disabled:bg-transparent disabled:text-gray-500 disabled:cursor-not-allowed" disabled={Array.length(conversations) == 0 || List.length(selectedConversations) == Array.length(conversations) }onClick={_evt => onToggleSelectAll(true)}>
            <i className="icon-check" />
            <span className="hidden lg:block">{"Alles auswählen"->React.string}</span>
          </button>
          <button
            className="flex flex-col items-center w-full hover:bg-blue-200 p-2 hover:disabled:bg-transparent justify-center disabled:text-gray-500 disabled:cursor-not-allowed" disabled={List.length(selectedConversations) == 0} onClick=onMassReply>
            <i className="icon-mail-reply-all" />
            <span className="hidden lg:block">{"Sammelantwort"->React.string}</span>
          </button>
          <button
            className="flex flex-col items-center w-full justify-center hover:bg-blue-200 p-2 hover:disabled:bg-transparent disabled:text-gray-500 disabled:cursor-not-allowed"
            disabled={List.length(selectedConversations) == 0}
            onClick={_evt => onMassTrash()}>
            <i className="icon-trash" />
            <span className="hidden lg:block">{"Löschen"->React.string}</span>
          </button>
        </div>
      } else {
        React.null
      }}
      <input
        className="w-full p-2 border"
        type_="search"
        placeholder={`Nach Name, E-Mail, Telefon suchen …`}
        onChange=onFilterTextChange
      />
    </div>
    <div className="overflow-y-auto h-auto lg:h-screen">
      {if loading {
        <p className="loadingState">
          {"Bitte warten, die Nachrichten werden geladen …"->React.string}
        </p>
      } else if Array.length(conversations) > 0 {
        conversations
        ->Belt.Array.map((conversation: conversation) => {
          let active = Some(conversation) == currentConversation
          <ConversationListItem
            key={string_of_int(conversation.id)}
            conversation
            selected={elementInList(conversation.id, selectedConversations)}
            active
            onClick={_evt => {
              if !active {
                onConversationClick(conversation)
              }
            }}
            onRating
            onToggleSelect
          />
        })
        ->React.array
      } else {
        <p className="p-2 w-full">
          {
            if hasAnyConversations {
              "Es sind noch keine Nachrichten eingegangen."
            } else if isFiltered {
              "Ihre Suche lieferte keine Ergebnisse."
            } else {
              switch folder {
              | New => "Es liegen keine neuen oder unbearbeitenen Nachrichten vor."
              | Trash => "Der Papierkorb ist leer."
              | _ => "In diesem Ordner befinden sich keine Nachrichten."
              }
            }->React.string
          }
        </p>
      }}
    </div>
  </div>
}
