/*%%raw(`import './ConversationPrinter.css'`)*/

@scope("window") @val external print: unit => unit = "print"

open ConversationData

@react.component
let make = (~conversation as _: conversation) => {
    <div 
      className="flex lg:flex-row flex-col justify-center items-center bg-white py-2 lg:py-1 px-2 hover:bg-blue-100 lg:border border-y border-l cursor-pointer w-full lg:w-auto" 
      onClick={_event => print()}
    >
        <i className="icon-print mr-1" title="Unterhaltung drucken" /> 
        <span>{"Drucken"->React.string}</span>
    </div>
}
