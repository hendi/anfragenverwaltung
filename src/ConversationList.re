[%bs.raw {|require('./ConversationList.css')|}];

open Utils;

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationList");

let make =
    (
      ~folder: folder,
      ~loading: bool,
      ~current_conversation: option(conversation),
      ~conversations: array(conversation),
      ~selected_conversations: list(int),
      ~onClick,
      ~onRating,
      ~onTrash,
      ~onReadStatus,
      ~onToggle,
      ~onSelectAll,
      ~onFilterTextChange,
      ~onMassReply,
      ~onMassTrash,
      _children,
      ~hasAnyConversations,
      ~isFiltered,
    ) => {
  ...component,
  render: _self =>
    <div className="ConversationList">
      <div className="header">
        {if (folder != Trash) {
           <div>
             <button
               className="btn"
               disabled={
                 List.length(selected_conversations)
                 == Array.length(conversations)
               }
               onClick=onSelectAll>
               <i className="icon-check" />
               {textEl({js|Alle auswählen|js})}
             </button>
             <button
               className="btn"
               disabled={selected_conversations |> List.length == 0}
               onClick=onMassReply>
               <i className="icon-mail-reply-all" />
               {textEl("Sammelantwort")}
             </button>
             <button
               className="btn pull-right"
               disabled={selected_conversations |> List.length == 0}
               onClick=onMassTrash>
               <i className="icon-trash" />
               {textEl({js|Löschen|js})}
             </button>
           </div>;
         } else {
           ReasonReact.null;
         }}
        <input
          className="search"
          type_="search"
          placeholder={js|Nach Name, E-Mail, Telefon suchen …|js}
          onChange=onFilterTextChange
        />
      </div>
      <div className="list scrollable">
        {if (loading) {
           <p className="loadingState">
             {textEl({js|Bitte warten, die Nachrichten werden geladen …|js})}
           </p>;
         } else if (Array.length(conversations) > 0) {
           conversations
           |> Array.map((conversation: conversation) =>
                <ConversationListItem
                  key={string_of_int(conversation.id)}
                  conversation
                  selected={element_in_list(
                    conversation.id,
                    selected_conversations,
                  )}
                  active={Some(conversation) == current_conversation}
                  onClick
                  onRating
                  onTrash
                  onReadStatus
                  onToggle
                />
              )
           |> arrayEl;
         } else {
           <p className="emptyState">
             {textEl(
                if (!hasAnyConversations) {
                  "Es sind noch keine Nachrichten eingegangen.";
                } else if (isFiltered) {
                  "Ihre Suche lieferte keine Ergebnisse.";
                } else {
                  switch (folder) {
                  | New => "Es liegen keine neuen oder unbearbeitenen Nachrichten vor."
                  | Trash => "Der Papierkorb ist leer."
                  | _ => "In diesem Ordner befinden sich keine Nachrichten."
                  };
                },
              )}
           </p>;
         }}
      </div>
    </div>,
};