%raw(`require('./app.css')`)

open Utils
open Belt.Option

open ConversationData

module App = {
  type route =
    | ConversationList(folder)
    | Conversation
    | MassReply
  type state = {
    route: route,
    active_folder: folder,
    filter_text: string,
    last_scroll_position: int,
    loading_conversations: bool,
    conversations: array<conversation>,
    loading_messages: bool,
    current_conversation_messages: list<message>,
    current_conversation: option<conversation>,
    interacted_with_conversations: list<int>,
    selected_conversations: list<int>,
    mainRef: ref<option<Dom.element>>,
    timerId: ref<option<Js.Global.intervalId>>,
  }
  type action =
    | ShowRoute(route)
    | LoadingConversations
    | LoadedConversations(array<conversation>)
    | LoadedConversationMessages(array<message>)
    | SetConversationRating(conversation, rating)
    | SetConversationTrash(conversation, bool)
    | SetConversationReadStatus(conversation, bool)
    | SetConversationIgnore(conversation, bool)
    | ToggleConversation(conversation)
    | SelectOrUnselectAllConversations(bool)
    | ShowConversation(conversation)
    | ReplyToConversation(conversation, message)
    | SendMassReply(array<conversation>, string, array<string>, string => int)
    | SetMassTrash(array<conversation>)
    | SaveConversationNotes(conversation, string)
    | FilterTextChanged(string)
  let component = React.reducerComponent("App")
  let setMainRef = (theRef, {React.state: state}) =>
    state.mainRef := Js.Nullable.toOption(theRef)
  let make = (~immobilie_id: int, _children) => {
    let filter_conversations = (
      interacted_with_conversations: list<int>,
      conversations: array<conversation>,
      filter_text: string,
      folder: folder,
    ) => {
      let conversations =
        filter_text === ""
          ? conversations
          : conversations
            |> Array.to_list
            |> List.filter(c =>
              if filter_text == "" {
                true
              } else {
                string_contains(c.name |> String.lowercase, filter_text) ||
                (string_contains(c.email |> String.lowercase, filter_text) ||
                (string_contains(c.phone->getWithDefault("") |> String.lowercase, filter_text) ||
                (string_contains(c.city->getWithDefault("") |> String.lowercase, filter_text) ||
                (string_contains(c.zipcode->getWithDefault("") |> String.lowercase, filter_text) ||
                (string_contains(c.street->getWithDefault("") |> String.lowercase, filter_text) ||
                (string_contains(c.latest_message.content |> String.lowercase, filter_text) ||
                string_contains(c.notes, filter_text)))))))
              }
            )
            |> Array.of_list

      switch folder {
      | All =>
        conversations
        |> Array.to_list
        |> List.filter(c =>
          !c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
        )
        |> Array.of_list
      | New =>
        conversations
        |> Array.to_list
        |> List.filter((c: conversation) =>
          (!c.is_in_trash && (c.rating == None && (!c.is_replied_to && !c.is_ignored))) ||
            ((!c.is_in_trash && !c.is_read) ||
            List.exists((c_id: int) => c_id == c.id, interacted_with_conversations))
        )
        |> Array.of_list
      | ByRating(rating) =>
        conversations
        |> Array.to_list
        |> List.filter(c =>
          (!c.is_in_trash && c.rating == rating) ||
            List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
        )
        |> Array.of_list
      | Unreplied =>
        conversations
        |> Array.to_list
        |> List.filter(c =>
          (!c.is_in_trash && (!c.is_replied_to && !c.is_ignored)) ||
            List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
        )
        |> Array.of_list
      | Replied =>
        conversations
        |> Array.to_list
        |> List.filter(c =>
          (!c.is_in_trash && c.has_been_replied_to) ||
            List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
        )
        |> Array.of_list
      | Trash =>
        conversations
        |> Array.to_list
        |> List.filter(c =>
          c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
        )
        |> Array.of_list
      }
    }
    let loadConversations = (self, ~silent) => {
      if !silent {
        self.React.send(LoadingConversations)
      }
      fetchConversations(immobilie_id, payload =>
        self.React.send(LoadedConversations(payload))
      )
    }
    {
      ...component,
      initialState: () => {
        route: ConversationList(New),
        last_scroll_position: 0,
        active_folder: New,
        loading_conversations: true,
        conversations: [],
        loading_messages: false,
        current_conversation_messages: list{},
        current_conversation: None,
        interacted_with_conversations: list{},
        selected_conversations: list{},
        mainRef: ref(None),
        timerId: ref(None),
        filter_text: "",
      },
      didMount: self => {
        loadConversations(self, ~silent=false)
        self.state.timerId :=
          Some(Js.Global.setInterval(() => loadConversations(self, ~silent=true), 1000 * 60))
        let watcherId = React.Router.watchUrl(url =>
          switch url.hash {
          | "conversations" => self.send(ShowRoute(ConversationList(All)))
          | _ => self.send(ShowRoute(ConversationList(All)))
          }
        )
        self.onUnmount(() => React.Router.unwatchUrl(watcherId))
        ()
      },
      reducer: (action, state) =>
        switch action {
        | FilterTextChanged(text) =>
          React.Update({
            ...state,
            filter_text: text |> String.trim |> String.lowercase,
          })

        | ShowRoute(ConversationList(folder)) =>
          let scroll_to =
            state.route == Conversation && folder == state.active_folder
              ? state.last_scroll_position
              : 0

          React.UpdateWithSideEffects(
            {
              ...state,
              active_folder: folder,
              route: ConversationList(folder),
              interacted_with_conversations: list{},
              selected_conversations: list{},
              current_conversation: None,
            },
            _self =>
              switch state.mainRef.contents {
              | None => ()
              | Some(domNode) => setScrollTop(domNode, scroll_to) |> ignore
              },
          )
        | ShowRoute(route) =>
          React.Update({
            ...state,
            route: route,
            current_conversation: None,
            last_scroll_position: switch state.mainRef.contents {
            | None => -1
            | Some(domNode) => getScrollTop(domNode)
            },
          })
        | LoadingConversations => React.Update({...state, loading_conversations: true})
        | LoadedConversations(conversations) =>
          React.Update({
            ...state,
            loading_conversations: false,
            conversations: conversations,
          })
        | SetConversationRating(conversation: conversation, rating) =>
          let new_rating = conversation.rating == Some(rating) ? None : Some(rating)
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    rating: new_rating,
                    is_read: true,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                c.id == conversation.id
                  ? Some({...conversation, rating: new_rating, is_read: true})
                  : state.current_conversation
              | None => None
              },
              interacted_with_conversations: List.append(
                state.interacted_with_conversations,
                list{conversation.id},
              ),
            },
            _self => rateConversation(conversation, new_rating, _ => ()),
          )
        | SaveConversationNotes(conversation: conversation, notes: string) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    notes: notes,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                c.id == conversation.id
                  ? Some({...conversation, notes: notes})
                  : state.current_conversation
              | None => None
              },
            },
            _self => storeNotesForConversation(conversation, notes, _ => ()),
          )
        | SetConversationTrash(conversation: conversation, is_in_trash) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    is_in_trash: is_in_trash,
                    is_read: is_in_trash,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                c.id == conversation.id
                  ? Some({
                      ...conversation,
                      is_in_trash: is_in_trash,
                      is_read: is_in_trash,
                    })
                  : state.current_conversation
              | None => None
              },
              interacted_with_conversations: List.append(
                state.interacted_with_conversations,
                list{conversation.id},
              ),
            },
            _self => trashConversation(conversation, is_in_trash, _ => ()),
          )
        | SetConversationReadStatus(conversation: conversation, is_read) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    is_read: is_read,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                c.id == conversation.id
                  ? Some({...conversation, is_read: is_read})
                  : state.current_conversation
              | None => None
              },
              interacted_with_conversations: List.append(
                state.interacted_with_conversations,
                list{conversation.id},
              ),
            },
            _self => setReadStatusForConversation(conversation, is_read, _ => ()),
          )
        | SetConversationIgnore(conversation: conversation, is_ignored) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    is_ignored: is_ignored,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                c.id == conversation.id
                  ? Some({...conversation, is_ignored: is_ignored})
                  : state.current_conversation
              | None => None
              },
            },
            _self => ignoreConversation(conversation, is_ignored, _ => ()),
          )
        | ReplyToConversation(conversation: conversation, reply: message) =>
          React.Update({
            ...state,
            conversations: Array.map((c: conversation): conversation =>
              if c.id == conversation.id {
                {
                  ...c,
                  count_messages: c.count_messages + 1,
                  is_replied_to: true,
                  is_read: true,
                  latest_message: reply,
                }
              } else {
                c
              }
            , state.conversations),
            current_conversation: switch state.current_conversation {
            | Some(c) =>
              c.id == conversation.id
                ? Some({
                    ...conversation,
                    count_messages: c.count_messages + 1,
                    is_replied_to: true,
                    latest_message: reply,
                  })
                : state.current_conversation
            | None => None
            },
          })
        | SendMassReply(
            conversations: array<conversation>,
            message_text: string,
            attachments: array<string>,
            cbFunc,
          ) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if List.exists((x: conversation) => x.id == c.id, Array.to_list(conversations)) {
                  {
                    ...c,
                    count_messages: c.count_messages + 1,
                    is_replied_to: true,
                    is_read: true,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: switch state.current_conversation {
              | Some(c) =>
                List.exists((x: conversation) => x.id == c.id, Array.to_list(conversations))
                  ? Some({
                      ...c,
                      count_messages: c.count_messages + 1,
                      is_replied_to: true,
                    })
                  : state.current_conversation
              | None => None
              },
            },
            _self =>
              postMassReply(immobilie_id, conversations, message_text, attachments, _ =>
                cbFunc("")
              ),
          )
        | SetMassTrash(conversations) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              conversations: Array.map((c: conversation): conversation =>
                if List.exists((x: conversation) => x.id == c.id, Array.to_list(conversations)) {
                  {
                    ...c,
                    is_read: true,
                    is_in_trash: true,
                  }
                } else {
                  c
                }
              , state.conversations),
              selected_conversations: list{},
            },
            _self => postMassTrash(immobilie_id, conversations),
          )
        | ShowConversation(conversation) =>
          React.UpdateWithSideEffects(
            {
              ...state,
              loading_messages: true,
              current_conversation_messages: list{},
              conversations: Array.map((c: conversation): conversation =>
                if c.id == conversation.id {
                  {
                    ...c,
                    is_read: true,
                  }
                } else {
                  c
                }
              , state.conversations),
              current_conversation: Some({...conversation, is_read: true}),
              route: Conversation,
              interacted_with_conversations: List.append(
                state.interacted_with_conversations,
                list{conversation.id},
              ),
            },
            self =>
              fetchConversationMessages(conversation, payload =>
                self.React.send(LoadedConversationMessages(payload))
              ),
          )
        | LoadedConversationMessages(messages) =>
          React.Update({
            ...state,
            loading_messages: false,
            current_conversation_messages: messages |> Array.to_list,
          })
        | ToggleConversation(conversationToToggle) =>
          let selected_conversations = element_in_list(
            conversationToToggle.id,
            state.selected_conversations,
          )
          /* remove */
            ? List.filter(
                (c_id: int) => c_id != conversationToToggle.id,
                state.selected_conversations,
              )
            : List.append(state.selected_conversations, list{conversationToToggle.id})
          React.Update({...state, selected_conversations: selected_conversations})
        | SelectOrUnselectAllConversations(selected) =>
          let selected_conversations = selected
            ? Array.map(
                (c: conversation) => c.id,
                filter_conversations(
                  list{},
                  state.conversations,
                  state.filter_text,
                  state.active_folder,
                ),
              ) |> Array.to_list
            : list{}
          React.Update({...state, selected_conversations: selected_conversations})
        },
      render: self =>
        <div className="App">
          <FolderNavigation
            onClick={(folder, _event) => self.React.send(ShowRoute(ConversationList(folder)))}
            active_folder=self.state.active_folder
            counter={filter_conversations(list{}, self.state.conversations, "")}
          />
          <div className="ConversationListView" ref={self.handle(setMainRef)}>
            <ConversationList
              folder=self.state.active_folder
              loading=self.state.loading_conversations
              current_conversation=self.state.current_conversation
              conversations={filter_conversations(
                self.state.interacted_with_conversations,
                self.state.conversations,
                self.state.filter_text,
                self.state.active_folder,
              )}
              selected_conversations=self.state.selected_conversations
              onClick={(conversation, _event) =>
                self.React.send(ShowConversation(conversation))}
              onFilterTextChange={event =>
                self.React.send(FilterTextChanged((event->ReactEvent.Form.target)["value"]))}
              onRating={(conversation, rating, _event) =>
                self.React.send(SetConversationRating(conversation, rating))}
              onTrash={(conversation, trash, _event) =>
                self.React.send(SetConversationTrash(conversation, trash))}
              onReadStatus={(conversation, is_read, _event) =>
                self.React.send(SetConversationReadStatus(conversation, is_read))}
              onToggle={conversation => self.React.send(ToggleConversation(conversation))}
              onSelectAll={_conversation =>
                self.React.send(SelectOrUnselectAllConversations(true))}
              onMassReply={_event => self.React.send(ShowRoute(MassReply))}
              onMassTrash={_event =>
                self.React.send(
                  SetMassTrash(
                    array_filter(
                      (c: conversation) => element_in_list(c.id, self.state.selected_conversations),
                      self.state.conversations,
                    ),
                  ),
                )}
              isFiltered={String.length(self.state.filter_text) > 0}
              hasAnyConversations={Array.length(self.state.conversations) > 0}
            />
          </div>
          <div className="MessageListView">
            {switch self.state.route {
            | Conversation =>
              switch self.state.current_conversation {
              | Some(conversation) =>
                <Conversation
                  key={conversation.id |> string_of_int}
                  conversation
                  loading=self.state.loading_messages
                  messages={self.state.current_conversation_messages |> Array.of_list}
                  onRating={(conversation, rating, _event) =>
                    self.React.send(SetConversationRating(conversation, rating))}
                  onTrash={(conversation, trash, _event) =>
                    self.React.send(SetConversationTrash(conversation, trash))}
                  onReadStatus={(conversation, is_read, _event) =>
                    self.React.send(SetConversationReadStatus(conversation, is_read))}
                  onReplySent={(reply: message) =>
                    self.React.send(ReplyToConversation(conversation, reply))}
                  onIgnore={conversation =>
                    self.React.send(SetConversationIgnore(conversation, true))}
                  onSaveNotes={(conversation, notes) =>
                    self.React.send(SaveConversationNotes(conversation, notes))}
                  onBack={_event =>
                    self.React.send(ShowRoute(ConversationList(self.state.active_folder)))}
                />
              | _ => <div> {textEl("Invalid current_conversation")} </div>
              }
            | MassReply =>
              <MassReply
                conversations={array_filter(
                  (c: conversation) => element_in_list(c.id, self.state.selected_conversations),
                  self.state.conversations,
                )}
                onMassReplySent={(conversations, message_text, attachments, cbFunc) =>
                  self.React.send(
                    SendMassReply(conversations, message_text, attachments, cbFunc),
                  )}
              />
            | ConversationList(_) => <div />
            }}
          </div>
        </div>,
    }
  }
}

let default = immobilie_id => ReactDOMRe.renderToElementWithId(<App immobilie_id />, "root")
