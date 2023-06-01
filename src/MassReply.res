open ConversationData

type state = {
  sending: bool,
  sent: bool,
  messageText: string,
  uploadsInProgress: int,
}

type action =
  | MessageTextChanged(string)
  | SendMessage
  | ReplySent
  | UploadStarted
  | UploadFinished

let initialState = {
  sending: false,
  sent: false,
  messageText: "",
  uploadsInProgress: 0,
}

let cbSent = self => {
  self.ReactUpdate.send(ReplySent)
  1
}

@react.component
let make = (~conversations, ~onMassReplySent) => {
  let filepondRef: React.ref<option<Filepond.Instance.t>> = React.useRef(None)

  let (state, send) = ReactUpdate.useReducer((state, action) =>
    switch action {
    | UploadStarted =>
      ReactUpdate.Update({
        ...state,
        uploadsInProgress: state.uploadsInProgress + 1,
      })
    | UploadFinished =>
      ReactUpdate.Update({
        ...state,
        uploadsInProgress: state.uploadsInProgress - 1,
      })
    | MessageTextChanged(text) => ReactUpdate.Update({...state, messageText: text})
    | SendMessage =>
      ReactUpdate.UpdateWithSideEffects(
        {...state, sending: true},
        self => {
          let attachments = switch filepondRef.current {
          | Some(filepond) =>
            let files = filepond->Filepond.Instance.getFiles
            files->Belt.Array.map(f => f.serverId)
          | None => []
          }

          onMassReplySent(conversations, self.state.messageText, attachments, _ => cbSent(self))
          None
        },
      )
    | ReplySent => ReactUpdate.Update({...state, sending: false, sent: true})
    }
  , initialState)

  <div className="p-2">
    <h2 className="text-xl font-semibold"> {"Sammelantwort schreiben"->React.string} </h2>
    <p>
      {"Hinweis: Die Empänger der Nachricht sehen nicht, dass es sich um eine Sammelantwort handelt."->React.string}
    </p>
    <div className="flex flex-col space-y-2 mb-4">
      <strong> {"Empfänger:"->React.string} </strong>
      <div className="flex flex-row gap-2">
      {conversations
      ->Array.map((conversation: conversation) =>
        <div
          className="bg-gray-200 rounded-full px-2 py-1" key={"recipient_" ++ Belt.Int.toString(conversation.id)}>
          {conversation.name->React.string}
        </div>
      )
      ->React.array}
      </div>
    </div>
    {if state.sent {
      <div className="bg-green-100 text-green-700 rounded p-2">
        {"Ihre Sammelantwort wurde erfolgreich verschickt."->React.string}
      </div>
    } else {
      React.null
    }}
    <div className={state.sent ? "hidden" : ""}>
      <textarea
        className="w-full rounded p-2 border"
        rows=4
        value=state.messageText
        onChange={event => send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
        disabled={state.sending || state.sent}
      />
      <Filepond
        ref={pond => filepondRef.current = Some(pond)}
        onprocessfilestart={_ => send(UploadStarted)}
        onprocessfile={_ => send(UploadFinished)}
        labelIdle={`Sie können bis zu 3 Anhänge (jeweils max. 10MB) hochladen <span class="filepond--label-action"> [Dateien auswählen] </span>`}
        onremovefile={e => {
          let wasFullyUploaded = %raw(`
           function (resp) {
             return resp.serverId != null;
           }
           `)

          if !wasFullyUploaded(e) {
            send(UploadFinished)
          }
        }}
        maxFiles=3
        allowMultiple=true
        allowFileEncode=true
        maxFileSize="8MB"
        maxTotalFileSize="20MB"
        server={ConversationData.apiBaseUrl ++ "/anfragen/upload_attachment"}
      />
      <div className="flex justify-end">
      <button
        className="bg-blue-500 text-white rounded p-2 hover:bg-blue-400 disabled:bg-slate-50 disabled:text-gray-500 disabled:border-slate-200 disabled:border disabled:cursor-not-allowed"
        onClick={_event => send(SendMessage)}
        disabled={String.length(state.messageText) == 0 || (state.sending || state.sent)}>
        {
          switch (state.sending, state.sent) {
          | (false, false) => "Antwort senden"
          | (true, false) => "Wird gesendet..."
          | (_, true) => "Sammelantwort wurde verschickt"
          }->React.string
        }
      </button>
      </div>
    </div>
  </div>
}
