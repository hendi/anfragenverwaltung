%%raw(`import './MessageItem.css'`)

open Utils

open ConversationData

@react.component
let make = (~message: message) => {
    <div
      className={"MessageItem " ++
      switch message.type_ {
      | Incoming => "is_incoming"
      | Outgoing => "is_reply"
      }}>
      <span>
        {if message.type_ == Incoming {
          textEl("Geschrieben am ")
        } else {
          <span> <i className="icon-reply" /> {textEl("Beantwortet am ")} </span>
        }}
        <IsoDate date={Js.Date.fromString(message.date)} />
        {textEl(" um ")}
        <IsoTime date={Js.Date.fromString(message.date)} />
      </span>
      <hr />
      <p> {textEl(message.content)} </p>
      {if Array.length(message.attachments) > 0 {
        <div>
          <b> {textEl(`Anhänge`)} </b>
          <ul>
            {message.attachments
            |> Array.map((attachment: attachment) =>
              <li key=attachment.url>
                {if String.length(attachment.url) > 0 {
                  <a href=attachment.url> {textEl("Anhang: " ++ attachment.filename)} </a>
                } else {
                  textEl("Anhang: " ++ attachment.filename)
                }}
              </li>
            )
            |> arrayEl}
          </ul>
        </div>
      } else {
        React.null
      }}
    </div>
}
