/* %%raw(`import './MassReply.css'`) */

open Utils

open ConversationData

type state = {
  sending: bool,
  sent: bool,
  message_text: string,
  uploads_in_progress: int,
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
  message_text: "",
  uploads_in_progress: 0,
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
        uploads_in_progress: state.uploads_in_progress + 1,
      })
    | UploadFinished =>
      ReactUpdate.Update({
        ...state,
        uploads_in_progress: state.uploads_in_progress - 1,
      })
    | MessageTextChanged(text) => ReactUpdate.Update({...state, message_text: text})
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

          onMassReplySent(conversations, self.state.message_text, attachments, _ => cbSent(self))
          None
        },
      )
    | ReplySent => ReactUpdate.Update({...state, sending: false, sent: true})
    }
  , initialState)

  <div className="MassReply">
    <h2> {textEl("Sammelantwort schreiben")} </h2>
    <p className="info">
      {textEl(`Hinweis: Die Empänger der Nachricht sehen nicht, dass es sich um eine Sammelantwort handelt.`)}
    </p>
    <div className="recipient-list">
      <div>
        <strong> {textEl(`Empfänger:`)} </strong>
      </div>
      {conversations
      ->Array.map((conversation: conversation) =>
        <div
          className="recipient-list-item" key={"recipient_" ++ Belt.Int.toString(conversation.id)}>
          {conversation.name->React.string}
        </div>
      )
      ->React.array}
    </div>
    {if state.sent {
      <div className="alert alert-success">
        {textEl("Ihre Sammelantwort wurde erfolgreich verschickt.")}
      </div>
    } else {
      React.null
    }}
    <div className={state.sent ? "hidden" : ""}>
      <textarea
        value=state.message_text
        onChange={event => send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
        disabled={state.sending || state.sent}
      />
      <Filepond
        ref={pond => filepondRef.current = Some(pond)}
        onprocessfilestart={_ => send(UploadStarted)}
        onprocessfile={_ => send(UploadFinished)}
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
      <button
        className="btn-send btn btn-primary pull-right"
        onClick={_event => send(SendMessage)}
        disabled={String.length(state.message_text) == 0 || (state.sending || state.sent)}>
        {textEl(
          switch (state.sending, state.sent) {
          | (false, false) => "Antwort senden"
          | (true, false) => "Wird gesendet..."
          | (_, true) => "Sammelantwort wurde verschickt"
          },
        )}
      </button>
    </div>
  </div>
}
