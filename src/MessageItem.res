/* %%raw(`import './MessageItem.css'`) */

open ConversationData

@react.component
let make = (~message: message) => {
  <div
    className={"border-2 rounded bg-white px-4 py-4 " ++
    switch message.type_ {
    | Incoming => "mr-20"
    | Outgoing => "ml-20"
    }}>
    <span>
      {if message.type_ == Incoming {
        "Geschrieben am "->React.string
      } else {
        <span>
          <i className="icon-reply text-[#236ea2] mr-1" />
          {"Beantwortet am "->React.string}
        </span>
      }}
      <IsoDate date={Js.Date.fromString(message.date)} />
      {" um "->React.string}
      <IsoTime date={Js.Date.fromString(message.date)} />
    </span>
    <hr />
    <p> {message.content->React.string} </p>
    {if Array.length(message.attachments) > 0 {
      <div>
        <b> {"Anhänge"->React.string} </b>
        <ul>
          {message.attachments
          ->Array.map((attachment: attachment) =>
            <li key=attachment.url>
              {if String.length(attachment.url) > 0 {
                <a href=attachment.url> {("Anhang: " ++ attachment.filename)->React.string} </a>
              } else {
                ("Anhang: " ++ attachment.filename)->React.string
              }}
            </li>
          )
          ->React.array}
        </ul>
      </div>
    } else {
      React.null
    }}
  </div>
}
