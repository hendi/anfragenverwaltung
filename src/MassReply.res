%raw(`require('./MassReply.css')`)

open Utils

open ConversationData

type state = {
  sending: bool,
  sent: bool,
  message_text: string,
  filepondRef: ref<option<React.ref>>,
  uploads_in_progress: int,
}

type action =
  | MessageTextChanged(string)
  | SendMessage
  | ReplySent
  | UploadStarted
  | UploadFinished

let component = React.reducerComponent("MassReply")

let setFilepondRef = (theRef, {React.state: state}) =>
  state.filepondRef := Js.Nullable.toOption(theRef)

let make = (~conversations, ~onMassReplySent, _children) => {
  let cbSent = self => {
    self.React.send(ReplySent)
    1
  }
  {
    ...component,
    initialState: () => {
      sending: false,
      sent: false,
      message_text: "",
      filepondRef: ref(None),
      uploads_in_progress: 0,
    },
    reducer: (action, state) =>
      switch action {
      | UploadStarted =>
        React.Update({
          ...state,
          uploads_in_progress: state.uploads_in_progress + 1,
        })
      | UploadFinished =>
        React.Update({
          ...state,
          uploads_in_progress: state.uploads_in_progress - 1,
        })
      | MessageTextChanged(text) => React.Update({...state, message_text: text})
      | SendMessage =>
        React.UpdateWithSideEffects(
          {...state, sending: true},
          self => {
            let attachments: array<string> = switch state.filepondRef.contents {
            | Some(r) =>
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
            | None => []
            }

            onMassReplySent(conversations, self.state.message_text, attachments, _ => cbSent(self))
          },
        )
      | ReplySent => React.Update({...state, sending: false, sent: true})
      },
    render: self =>
      <div className="MassReply">
        <h2> {textEl("Sammelantwort schreiben")} </h2>
        <p className="info">
          {textEl(`Hinweis: Die Empänger der Nachricht sehen nicht, dass es sich um eine Sammelantwort handelt.`)}
        </p>
        <div className="recipient-list">
          <div> <strong> {textEl(`Empfänger:`)} </strong> </div>
          {conversations
          |> Array.map((conversation: conversation) =>
            <div
              className="recipient-list-item" key={"recipient_" ++ string_of_int(conversation.id)}>
              {textEl(conversation.name)}
            </div>
          )
          |> arrayEl}
        </div>
        {if self.state.sent {
          <div className="alert alert-success">
            {textEl("Ihre Sammelantwort wurde erfolgreich verschickt.")}
          </div>
        } else {
          React.null
        }}
        <div className={self.state.sent ? "hidden" : ""}>
          <textarea
            value=self.state.message_text
            onChange={event =>
              self.send(MessageTextChanged((event->ReactEvent.Form.target)["value"]))}
            disabled={self.state.sending || self.state.sent}
          />
          <Filepond
            ref={self.handle(setFilepondRef)}
            onprocessfilestart={_ => self.send(UploadStarted)}
            onprocessfile={_ => self.send(UploadFinished)}
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
            maxFileSize="8MB"
            maxTotalFileSize="20MB"
            server={ConversationData.apiBaseUrl ++ "/anfragen/upload_attachment"}
          />
          <button
            className="btn-send btn btn-primary pull-right"
            onClick={_event => self.send(SendMessage)}
            disabled={String.length(self.state.message_text) == 0 ||
              (self.state.sending ||
              self.state.sent)}>
            {textEl(
              switch (self.state.sending, self.state.sent) {
              | (false, false) => "Antwort senden"
              | (true, false) => "Wird gesendet..."
              | (_, true) => "Sammelantwort wurde verschickt"
              },
            )}
          </button>
        </div>
      </div>,
  }
}
