%raw(`require('./Conversation.css')`)

open Utils

open ConversationData

type state = {
  show_notes: bool,
  notes: string,
  scrollableRef: ref<option<Dom.element>>,
}

type action =
  | LoadingMessages
  | LoadedMessages(array<message>)
  | ReplySent(message)
  | IgnoreConversation
  | ToggleNotes
  | NotesChanged(string)
  | SaveNotes

let component = React.reducerComponent("Conversation")

let setScrollableRef = (theRef, {React.state: state}) =>
  state.scrollableRef := Js.Nullable.toOption(theRef)

let make = (
  ~conversation: conversation,
  ~onReplySent,
  ~onRating,
  ~onTrash,
  ~onReadStatus,
  ~onIgnore,
  ~onSaveNotes,
  ~onBack,
  ~messages: array<message>,
  ~loading: bool,
  _children,
) => {
  let sendReply = (self, conversation: conversation, message_text, attachments) =>
    postReply(conversation, message_text, attachments, reply => {
      self.React.send(ReplySent(reply))
      onReplySent(reply)
    })
  let ignoreConversation = (self, conversation: conversation) => {
    self.React.send(IgnoreConversation)
    onIgnore(conversation)
  }
  {
    ...component,
    initialState: () => {
      show_notes: false,
      notes: conversation.notes,
      scrollableRef: ref(None),
    },
    reducer: (action, state) =>
      switch action {
      | ReplySent(reply) =>
        React.UpdateWithSideEffects(
          state,
          /* TODO
             {
               ...state,
               messages: Array.make(1, reply) |> Array.append(state.messages),
             },*/
          _self => {
            let scrollElementToTop: Dom.element => int = %raw(`
                 function (domNode) {
                 domNode.scrollTop = 99999999;
                   return 0;
                 }
                 `)
            switch state.scrollableRef.contents {
            | None => ()
            | Some(domNode) => scrollElementToTop(domNode) |> ignore
            }
          },
        )
      | IgnoreConversation => React.NoUpdate
      | ToggleNotes => React.Update({...state, show_notes: !state.show_notes})
      | NotesChanged(notes) => React.Update({...state, notes: notes})
      | SaveNotes =>
        React.UpdateWithSideEffects(state, _self => onSaveNotes(conversation, state.notes))
      },
    render: self =>
      <div
        className={list{
          "Conversation",
          switch conversation.rating {
          | Some(Green) => "rating-green"
          | Some(Yellow) => "rating-yellow"
          | Some(Red) => "rating-red"
          | _ => "rating-unrated"
          },
          conversation.is_in_trash ? "is_in_trash" : "",
        } |> String.concat(" ")}>
        <div className="header">
          <div className="pull-right" style={ReactDOMRe.Style.make(~paddingTop="2px", ())}>
            <ConversationPrinter conversation />
            <ConversationReadStatus conversation onReadStatus />
            <ConversationTrasher conversation onTrash />
            <ConversationRater conversation onRating />
          </div>
          <h2> {textEl(conversation.name)} </h2>
          <span> <strong> {textEl("E-Mail: ")} </strong> {textEl(conversation.email)} </span>
          {switch conversation.phone {
          | Some("") => React.null
          | Some(phone) => <span> <strong> {textEl("Telefon: ")} </strong> {textEl(phone)} </span>
          | None => React.null
          }}
          {switch (conversation.street, conversation.zipcode, conversation.city) {
          | (Some(""), Some(""), _) => React.null
          | (Some(""), Some(zipcode), Some(city)) =>
            <span>
              <strong> {textEl("Adresse: ")} </strong> {textEl(zipcode ++ (" " ++ city))}
            </span>
          | (Some(street), Some(zipcode), Some(city)) =>
            <span>
              <strong> {textEl("Adresse: ")} </strong>
              {textEl(street ++ (", " ++ (zipcode ++ (" " ++ city))))}
            </span>
          | _ => React.null
          }}
          <span> <strong> {textEl("Via: ")} </strong> {textEl(conversation.source)} </span>
          {if String.length(self.state.notes) > 0 {
            <div className="hidden-unless-print">
              <strong> {textEl("Private Notizen: ")} </strong>
              <p className="nl2br"> {textEl(self.state.notes)} </p>
            </div>
          } else {
            React.null
          }}
          <div className="notes hidden-on-print">
            <a onClick={_event => self.send(ToggleNotes)}>
              <i className={self.state.show_notes ? "icon-caret-down" : "icon-caret-right"} />
              {if String.length(self.state.notes) > 0 || String.length(conversation.notes) > 0 {
                <strong> {textEl("Private Notizen")} </strong>
              } else {
                textEl("Private Notizen")
              }}
            </a>
            {if self.state.show_notes {
              <div>
                <textarea
                  value=self.state.notes
                  onChange={event =>
                    self.send(NotesChanged((event->ReactEvent.Form.target)["value"]))}
                />
                {if self.state.notes != conversation.notes {
                  <button
                    className="btn btn-primary"
                    onClick={_event => self.send(SaveNotes)}
                    disabled={self.state.notes == conversation.notes}>
                    {textEl("Notizen speichern")}
                  </button>
                } else {
                  React.null
                }}
              </div>
            } else {
              React.null
            }}
          </div>
        </div>
        <div className="main scrollable" ref={self.handle(setScrollableRef)}>
          <div>
            {if loading {
              <p> {textEl("Nachrichten werden geladen...")} </p>
            } else {
              messages
              |> Array.map((message: message) =>
                <MessageItem key={string_of_int(message.id)} message />
              )
              |> arrayEl
            }}
          </div>
          {if !conversation.is_in_trash {
            <ReplyEditor
              key={conversation.id |> string_of_int}
              conversation
              onReplySent={sendReply(self)}
              onIgnoreConversation={_event => ignoreConversation(self, conversation)}
            />
          } else {
            React.null
          }}
        </div>
      </div>,
  }
}
