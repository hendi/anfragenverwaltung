%raw(`require('./ConversationPrinter.css')`)

@scope("window") @val external print: unit => unit = "print"

open ConversationData
open Utils

@react.component
let make = (~conversation: conversation) => {
    <div className="ConversationPrinter">
      <span className="btn" onClick={_event => print()}>
        <i className="icon-print" title="Unterhaltung drucken" /> {textEl("Drucken")}
      </span>
    </div>
}
