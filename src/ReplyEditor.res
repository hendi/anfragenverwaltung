%raw(`require('./ReplyEditor.css')`)

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

let reducer = (state, action) => {
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
          ...state, message_text: text
        }
        | SendMessage => {
          let attachments: array<string> = switch filepondRef.current->Js.Nullable.toOption {
              | Some(r) => {
                let files = React.refToJsObj(r)["getFiles"]()
                let getIds = %raw(`
                     function(fs) {
                       var ret = [];
                       for (var i=0; i<fs.length; i++) {
                         ret.push(fs[i].serverId);
                       }
                       return ret;

                     }
                  `)
                getIds(files)
              }
              | None => []
          }

          onReplySent(conversation, state.message_text, attachments)

          {...state, message_text: "", message_sent: true}
        }
    }
}


@react.component
let make = (
  ~conversation: ConversationData.conversation,
  ~onReplySent,
  ~onIgnoreConversation,
) => {
  let initialState = {
    message_text: "",
    uploads_in_progress: 0,
    message_sent: false,
  };
  let (state, dispatch) = React.useReducer(reducer, initialState);

  let filepondRef = React.useRef(Js.Nullable.null);

    <div className="ReplyEditor">
      <h2> {textEl("Antwort schreiben:")} </h2>
      {if self.state.message_sent {
        <div className="alert alert-success">
          {textEl("Ihre Nachricht wurde erfolgreich verschickt.")}
        </div>
      } else {
        React.null
      }}
      <div className={self.state.message_sent ? "hidden" : ""}>
        <textarea
          value=self.state.message_text
          onChange={event =>
            self.send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
        />
        <Filepond
          ref={ReactDOM.Ref.domRef(filepondRef)}
          onprocessfilestart={_ => self.send(UploadStarted)}
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
              self.send(UploadFinished)
            }
          }}
          onremovefile={e => {
            let wasFullyUploaded = %raw(`
           function (resp) {
             return resp.serverId != null;
           }
           `)

            if !wasFullyUploaded(e) {
              self.send(UploadFinished)
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
          disabled={String.length(self.state.message_text) == 0}
            /* || self.state.uploads_in_progress != 0 */
          onClick={_event => self.send(SendMessage)}>
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
