/*%%raw(`import './ConversationList.css'`)*/

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
  ~onTrash,
  ~onReadStatus,
  ~onToggleSelect: conversation => unit,
  ~onToggleSelectAll: bool => unit,
  ~onFilterTextChange,
  ~onMassReply,
  ~onMassTrash: unit => unit,
  ~hasAnyConversations,
  ~isFiltered,
) => {
  <div className="ConversationList">
    <div className="header">
      {if folder != Trash {
        <div>
          {
            let (text, selected) = if (
              List.length(selectedConversations) == Array.length(conversations)
            ) {
              (`Auswahl löschen`, false)
            } else {
              (`Alle auswählen`, true)
            }
            <button className="btn" onClick={_evt => onToggleSelectAll(selected)}>
              <i className="icon-check" /> {textEl(text)}
            </button>
          }
          <button
            className="btn"
            disabled={selectedConversations |> List.length == 0}
            onClick=onMassReply>
            <i className="icon-mail-reply-all" /> {textEl("Sammelantwort")}
          </button>
          <button
            className="btn pull-right"
            disabled={selectedConversations |> List.length == 0}
            onClick={_evt => onMassTrash()}>
            <i className="icon-trash" /> {textEl(`Löschen`)}
          </button>
        </div>
      } else {
        React.null
      }}
      <input
        className="search"
        type_="search"
        placeholder=`Nach Name, E-Mail, Telefon suchen …`
        onChange=onFilterTextChange
      />
    </div>
    <div className="list space-y-2 scrollable">
      {if loading {
        <p className="loadingState">
          {textEl(`Bitte warten, die Nachrichten werden geladen …`)}
        </p>
      } else if Array.length(conversations) > 0 {
        conversations
        ->Belt.Array.map((conversation: conversation) => {
          let active = Some(conversation) == currentConversation
          <ConversationListItem
            key={string_of_int(conversation.id)}
            conversation
            selected={element_in_list(conversation.id, selectedConversations)}
            active
            onClick={evt => {
              ReactEvent.Mouse.preventDefault(evt)
              // don't reload messages if this conversation is currently selected
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
        <p className="emptyState">
          {textEl(
            if !hasAnyConversations {
              "Es sind noch keine Nachrichten eingegangen."
            } else if isFiltered {
              "Ihre Suche lieferte keine Ergebnisse."
            } else {
              switch folder {
              | New => "Es liegen keine neuen oder unbearbeitenen Nachrichten vor."
              | Trash => "Der Papierkorb ist leer."
              | _ => "In diesem Ordner befinden sich keine Nachrichten."
              }
            },
          )}
        </p>
      }}
    </div>
  </div>
}
