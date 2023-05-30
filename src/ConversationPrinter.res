/*%%raw(`import './ConversationPrinter.css'`)*/

@scope("window") @val external print: unit => unit = "print"

open ConversationData

@react.component
let make = (~conversation as _: conversation) => {
    <div className="ConversationPrinter">
      <span onClick={_event => print()}>
        <i className="icon-print mr-1" title="Unterhaltung drucken" /> {"Drucken"->React.string}
      </span>
    </div>
}
