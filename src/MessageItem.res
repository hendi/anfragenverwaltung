open ConversationData
open Utils

@react.component
let make = (~message: message) => {
  <div
    className={"border-2 rounded bg-slate-50 px-4 py-4 " ++
    switch message.type_ {
    | Incoming => "lg:mr-20"
    | Outgoing => "lg:ml-20"
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
      <IsoDate date={Js.Date.fromString(replaceSpaceWithT(message.date))} />
      {" um "->React.string}
      <IsoTime date={Js.Date.fromString(replaceSpaceWithT(message.date))} />
    </span>
    <hr className="mb-2" />
    <p className="whitespace-pre-line"> {message.content->React.string} </p>
    {if Array.length(message.attachments) > 0 {
      <div>
        <strong> {"Anhänge"->React.string} </strong>
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
