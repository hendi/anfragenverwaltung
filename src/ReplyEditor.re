[%bs.raw {|require('./ReplyEditor.css')|}];

open Utils;

type state = {
  message_text: string,
  filepondRef: ref(option(ReasonReact.reactRef)),
  uploads_in_progress: int,
  message_sent: bool,
};

type action =
  | MessageTextChanged(string)
  | SendMessage
  | UploadStarted
  | UploadFinished;

let component = ReasonReact.reducerComponent("ReplyEditor");

let setFilepondRef = (theRef, {ReasonReact.state}) =>
  state.filepondRef := Js.Nullable.toOption(theRef);

let make =
    (
      ~conversation: ConversationData.conversation,
      ~onReplySent,
      ~onIgnoreConversation,
      _children,
    ) => {
  ...component,
  initialState: () => {
    message_text: "",
    filepondRef: ref(None),
    uploads_in_progress: 0,
    message_sent: false,
  },
  reducer: (action, state) =>
    switch (action) {
    | UploadStarted =>
      ReasonReact.Update({
        ...state,
        uploads_in_progress: state.uploads_in_progress + 1,
      })
    | UploadFinished =>
      ReasonReact.Update({
        ...state,
        uploads_in_progress: state.uploads_in_progress - 1,
      })
    | MessageTextChanged(text) =>
      ReasonReact.Update({...state, message_text: text})
    | SendMessage =>
      ReasonReact.UpdateWithSideEffects(
        {...state, message_text: "", message_sent: true},
        _self => {
          let attachments: array(string) =
            switch (state.filepondRef^) {
            | Some(r) =>
              let files = ReasonReact.refToJsObj(r)##getFiles();
              let getIds = [%bs.raw
                {|
                     function(fs) {
                       var ret = [];
                       for (var i=0; i<fs.length; i++) {
                         ret.push(fs[i].serverId);
                       }
                       return ret;

                     }
                  |}
              ];
              getIds(files);
            | None => [||]
            };

          onReplySent(conversation, state.message_text, attachments);
        },
      )
    },
  render: self =>
    <div className="ReplyEditor">
      <h2> {textEl("Antwort schreiben:")} </h2>
      {if (self.state.message_sent) {
         <div className="alert alert-success">
           {textEl("Ihre Nachricht wurde erfolgreich verschickt.")}
         </div>;
       } else {
         ReasonReact.null;
       }}
      <div className={self.state.message_sent ? "hidden" : ""}>
        <textarea
          value={self.state.message_text}
          onChange={event =>
            self.send(
              MessageTextChanged(event->ReactEvent.Form.target##value),
            )
          }
        />
        <Filepond
          ref={self.handle(setFilepondRef)}
          onprocessfilestart={_ => self.send(UploadStarted)}
          onprocessfile={e => {
            let wasSuccessfullyUploaded = [%bs.raw
              {|
           function (resp) {
           if (resp && resp.code && resp.code == 413) {
           alert("Die Datei ist leider zu groß, Anhänge können maximal 10MB groß sein.");
           return false;
           }
           return true;

           }
           |}
            ];

            if (wasSuccessfullyUploaded(e)) {
              self.send(UploadFinished);
            };
          }}
          onremovefile={e => {
            let wasFullyUploaded = [%bs.raw
              {|
           function (resp) {
             return resp.serverId != null;
           }
           |}
            ];

            if (!wasFullyUploaded(e)) {
              self.send(UploadFinished);
            };
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
          disabled={
            String.length(self.state.message_text) == 0
            /*|| self.state.uploads_in_progress != 0*/
          }
          onClick={_event => self.send(SendMessage)}>
          {textEl("Antwort senden")}
        </button>
        <button
          className="btn-ignore btn pull-right"
          onClick=onIgnoreConversation
          disabled={conversation.is_ignored}>
          {textEl({js|Keine Antwort nötig|js})}
        </button>
      </div>
    </div>,
};