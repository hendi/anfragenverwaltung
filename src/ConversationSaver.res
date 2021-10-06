%raw(`require('./ConversationSaver.css')`)

open ConversationData

let make = (~conversation: conversation, _children) => {
  <div className="ConversationSaver">
    <a
      href={"https://www.ohne-makler.net/anfragen/immobilie/" ++
      (Belt.Int.toString(conversation.immobilie_id) ++
      ("/backup/?c=" ++ Belt.Int.toString(conversation.id)))}
      target="_blank">
      <i className="icon-save" title="Unterhaltung als PDF herunterladen" />
    </a>
  </div>
}
