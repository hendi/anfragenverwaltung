%raw(`require('./ConversationTrasher.css')`)

open Utils

open ConversationData

@react.component
let make = (~conversation, ~onTrash) => {
    <div className="ConversationTrasher">
      {if conversation.is_in_trash {
        <span className="btn" onClick={onTrash(conversation, false)}>
          <i className="icon-undo" /> {textEl("Wiederherstellen")}
        </span>
      } else {
        <span className="btn" onClick={onTrash(conversation, !conversation.is_in_trash)}>
          <i className="icon-trash" /> {textEl(`Löschen`)}
        </span>
      }}
    </div>
}
