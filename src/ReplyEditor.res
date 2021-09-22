%%raw(`import './ReplyEditor.css'`)

open Utils

type state = {
  message_text: string,
  uploads_in_progress: int,
  message_sent: bool,
}

type action =
  | MessageTextChanged(string)
  | SendMessage
  | UploadStarted
  | UploadFinished

@react.component
let make = (
  ~conversation: ConversationData.conversation,
  ~onReplySent: (ConversationData.conversation, string, array<string>) => unit,
  ~onIgnoreConversation: ReactEvent.Mouse.t => unit,
) => {
  let initialState = {
    message_text: "",
    uploads_in_progress: 0,
    message_sent: false,
  }

  let filepondRef = React.useRef(None)

  let (state, send) = React.useReducer((state, action) => {
    switch action {
    | UploadStarted => {
        ...state,
        uploads_in_progress: state.uploads_in_progress + 1,
      }
    | UploadFinished => {
        ...state,
        uploads_in_progress: state.uploads_in_progress - 1,
      }
    | MessageTextChanged(text) => {
        ...state,
        message_text: text,
      }
    | SendMessage => {
        let attachments = switch filepondRef.current {
        | Some(filepond) => {
            let files = filepond->Filepond.Instance.getFiles
            files->Belt.Array.map(f => f.serverId)
          }
        | None => []
        }

        onReplySent(conversation, state.message_text, attachments)

        {...state, message_text: "", message_sent: true}
      }
    }
  }, initialState)

  <div className="ReplyEditor">
    <h2> {textEl("Antwort schreiben:")} </h2>
    {if state.message_sent {
      <div className="alert alert-success">
        {textEl("Ihre Nachricht wurde erfolgreich verschickt.")}
      </div>
    } else {
      React.null
    }}
    <div className={state.message_sent ? "hidden" : ""}>
      <textarea
        value=state.message_text
        onChange={event => send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
      />
      <Filepond
        ref={pond => filepondRef.current = Some(pond)}
        onprocessfilestart={_ => send(UploadStarted)}
        onprocessfile={e => {
          let wasSuccessfullyUploaded = %raw(`
           function (resp) {
           if (resp && resp.code && resp.code == 413) {
           alert("Die Datei ist leider zu groß, Anhänge können maximal 10MB groß sein.");
           return false;
           }
           return true;

           }
           `)

          if wasSuccessfullyUploaded(e) {
            send(UploadFinished)
          }
        }}
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
        maxFileSize="2MB"
        maxTotalFileSize="10MB"
        server={ConversationData.apiBaseUrl ++ "/anfragen/upload_attachment"}
      />
      <button
        className="btn-send btn btn-primary pull-right"
        disabled={String.length(state.message_text) == 0}
        /* || state.uploads_in_progress != 0 */
        onClick={_event => send(SendMessage)}>
        {textEl("Antwort senden")}
      </button>
      <button
        className="btn-ignore btn pull-right"
        onClick=onIgnoreConversation
        disabled=conversation.is_ignored>
        {textEl(`Keine Antwort nötig`)}
      </button>
    </div>
  </div>
}
