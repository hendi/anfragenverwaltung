/*%%raw(`import './ConversationPrinter.css'`)*/

@scope("window") @val external print: unit => unit = "print"

open ConversationData

@react.component
let make = (~conversation as _: conversation) => {
    <div className="bg-white py-1 px-2 hover:bg-blue-100 border">
      <span onClick={_event => print()}>
        <i className="icon-print mr-1" title="Unterhaltung drucken" /> {"Drucken"->React.string}
      </span>
    </div>
}
