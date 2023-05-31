/* %%raw(`import './ReplyEditor.css'`) */

type state = {
  messageText: string,
  uploadsInProgress: int,
  messageSent: bool,
}

type action =
  | MessageTextChanged(string)
  | SendReply
  | UploadStarted
  | UploadFinished

@react.component
let make = (
  ~conversation: ConversationData.conversation,
  ~onReplySend: (ConversationData.conversation, string, array<string>) => unit,
  ~onIgnoreConversation: ReactEvent.Mouse.t => unit,
) => {
  let initialState = {
    messageText: "",
    uploadsInProgress: 0,
    messageSent: false,
  }

  let filepondRef = React.useRef(None)

  let (state, send) = ReactUpdate.useReducer((state, action) => {
    switch action {
    | SendReply =>
      ReactUpdate.UpdateWithSideEffects(
        {...state, messageText: "", messageSent: true},
        _self => {
          let attachments = switch filepondRef.current {
          | Some(filepond) => {
              let files = filepond->Filepond.Instance.getFiles
              files->Belt.Array.map(f => f.serverId)
            }
          | None => []
          }
          onReplySend(conversation, state.messageText, attachments)
          None
        },
      )
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
    | MessageTextChanged(text) =>
      ReactUpdate.Update({
        ...state,
        messageText: text,
      })
    }
  }, initialState)

  <div className="space-y-4 ml-20 print:hidden">
    <h2 className="text-xl font-semibold text-blue-500"> {"Antwort schreiben:"->React.string} </h2>
    {if state.messageSent {
      <div className="bg-green-100 text-green-700 rounded p-2">
        {"Ihre Nachricht wurde erfolgreich verschickt."->React.string}
      </div>
    } else {
      React.null
    }}
    <div className={state.messageSent ? "hidden" : ""}>
      <textarea
        className="w-full rounded p-2 mb-2 border"
        rows=4
        value=state.messageText
        onChange={event => send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
      />
      <Filepond
        ref={pond => filepondRef.current = Some(pond)}
        onprocessfilestart={_ => send(UploadStarted)}
        labelIdle={`Sie können bis zu 3 Anhänge (jeweils max. 10MB) hochladen <span class="filepond--label-action"> [Dateien auswählen] </span>`}
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
      <div className="flex flex-row justify-end space-x-4">
       <button
        className="bg-slate-50 border border-slate-200 rounded p-2 disabled:text-gray-500 disabled:cursor-not-allowed"
        onClick=onIgnoreConversation
        disabled=conversation.is_ignored>
        {"Keine Antwort nötig"->React.string}
      </button>
      <button
        className="bg-blue-500 text-white rounded p-2 hover:bg-blue-400 disabled:bg-slate-50 disabled:text-gray-500 disabled:border-slate-200 disabled:border disabled:cursor-not-allowed"
        disabled={String.length(state.messageText) == 0}
        onClick={_evt => {
          send(SendReply)
        }}>
        {"Antwort senden"->React.string}
      </button>
      </div>
    </div>
  </div>
}
