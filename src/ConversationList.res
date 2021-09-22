%raw(`require('./ConversationList.css')`)

open Utils

open ConversationData

@react.component
let make = (
  ~folder: folder,
  ~loading: bool,
  ~current_conversation: option<conversation>,
  ~conversations: array<conversation>,
  ~selected_conversations: list<int>,
  ~onClick,
  ~onRating,
  ~onTrash,
  ~onReadStatus,
  ~onToggle,
  ~onSelectAll,
  ~onFilterTextChange,
  ~onMassReply,
  ~onMassTrash,
  ~hasAnyConversations,
  ~isFiltered,
) => {
    <div className="ConversationList">
      <div className="header">
        {if folder != Trash {
          <div>
            <button
              className="btn"
              disabled={List.length(selected_conversations) == Array.length(conversations)}
              onClick=onSelectAll>
              <i className="icon-check" /> {textEl(`Alle auswählen`)}
            </button>
            <button
              className="btn"
              disabled={selected_conversations |> List.length == 0}
              onClick=onMassReply>
              <i className="icon-mail-reply-all" /> {textEl("Sammelantwort")}
            </button>
            <button
              className="btn pull-right"
              disabled={selected_conversations |> List.length == 0}
              onClick=onMassTrash>
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
      <div className="list scrollable">
        {if loading {
          <p className="loadingState">
            {textEl(`Bitte warten, die Nachrichten werden geladen …`)}
          </p>
        } else if Array.length(conversations) > 0 {
          conversations
          |> Array.map((conversation: conversation) =>
            <ConversationListItem
              key={string_of_int(conversation.id)}
              conversation
              selected={element_in_list(conversation.id, selected_conversations)}
              active={Some(conversation) == current_conversation}
              onClick
              onRating
              onTrash
              onReadStatus
              onToggle
            />
          )
          |> arrayEl
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
