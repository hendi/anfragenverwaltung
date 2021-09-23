%%raw(`import './app.css'`)

@@warning("-3")

open Belt.Option

open ConversationData

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
            open Utils
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

  let initialState = {
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
    timerId: ref(None),
    filter_text: "",
  }

  @react.component
  let make = (~immobilie_id: int) => {
    let mainRef = React.useRef(Js.Nullable.null)

    let (state, send) = ReactUpdate.useReducer((state, action) =>
      switch action {
      | FilterTextChanged(text) =>
        ReactUpdate.Update({
          ...state,
          filter_text: text->Js.String2.trim->Js.String2.toLowerCase,
        })

      | ShowRoute(ConversationList(folder)) =>
        let scroll_to =
          state.route == Conversation && folder == state.active_folder
            ? state.last_scroll_position
            : 0

        ReactUpdate.UpdateWithSideEffects(
          {
            ...state,
            active_folder: folder,
            route: ConversationList(folder),
            interacted_with_conversations: list{},
            selected_conversations: list{},
            current_conversation: None,
          },
          _self =>
            switch mainRef.current->Js.Nullable.toOption {
            | None => None
            | Some(domNode) => Some(() => Utils.setScrollTop(domNode, scroll_to)->ignore)
            },
        )
      | ShowRoute(route) =>
        ReactUpdate.Update({
          ...state,
          route: route,
          current_conversation: None,
          last_scroll_position: switch mainRef.current->Js.Nullable.toOption {
          | None => -1
          | Some(domNode) => Utils.getScrollTop(domNode)
          },
        })
      | LoadingConversations => ReactUpdate.Update({...state, loading_conversations: true})
      | LoadedConversations(conversations) =>
        ReactUpdate.Update({
          ...state,
          loading_conversations: false,
          conversations: conversations,
        })
      | SetConversationRating(conversation: conversation, rating) =>
        let new_rating = conversation.rating == Some(rating) ? None : Some(rating)
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => rateConversation(conversation, new_rating, _ => ())),
        )
      | SaveConversationNotes(conversation: conversation, notes: string) =>
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => storeNotesForConversation(conversation, notes, _ => ())),
        )
      | SetConversationTrash(conversation: conversation, is_in_trash) =>
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => trashConversation(conversation, is_in_trash, _ => ())),
        )
      | SetConversationReadStatus(conversation: conversation, is_read) =>
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => setReadStatusForConversation(conversation, is_read, _ => ())),
        )
      | SetConversationIgnore(conversation: conversation, is_ignored) =>
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => ignoreConversation(conversation, is_ignored, _ => ())),
        )
      | ReplyToConversation(conversation: conversation, reply: message) =>
        ReactUpdate.Update({
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
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(
            () =>
              postMassReply(immobilie_id, conversations, message_text, attachments, _ =>
                cbFunc("")->ignore
              ),
          ),
        )
      | SetMassTrash(conversations) =>
        ReactUpdate.UpdateWithSideEffects(
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
          _self => Some(() => postMassTrash(immobilie_id, conversations)),
        )
      | ShowConversation(conversation) =>
        ReactUpdate.UpdateWithSideEffects(
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
          self => Some(
            () =>
              fetchConversationMessages(conversation, payload =>
                self.send(LoadedConversationMessages(payload))
              ),
          ),
        )
      | LoadedConversationMessages(messages) =>
        ReactUpdate.Update({
          ...state,
          loading_messages: false,
          current_conversation_messages: messages |> Array.to_list,
        })
      | ToggleConversation(conversationToToggle) =>
        let selected_conversations = Utils.element_in_list(
          conversationToToggle.id,
          state.selected_conversations,
        )
        /* remove */
          ? List.filter(
              (c_id: int) => c_id != conversationToToggle.id,
              state.selected_conversations,
            )
          : List.append(state.selected_conversations, list{conversationToToggle.id})
        ReactUpdate.Update({...state, selected_conversations: selected_conversations})
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
        ReactUpdate.Update({...state, selected_conversations: selected_conversations})
      }
    , initialState)

    let loadConversations = (~silent) => {
      if !silent {
        send(LoadingConversations)
      }

      ConversationData.fetchConversations(immobilie_id, payload =>
        send(LoadedConversations(payload))
      )
    }

    // useEffect with empty dependency array is basically equivalent to
    // componentDidMount (the first render of the component)
    React.useEffect0(() => {
      loadConversations(~silent=false)
      state.timerId := Some(Js.Global.setInterval(() => loadConversations(~silent=true), 1000 * 60))
      let watcherId = RescriptReactRouter.watchUrl(url =>
        switch url.hash {
        | "conversations" => send(ShowRoute(ConversationList(All)))
        | _ => send(ShowRoute(ConversationList(All)))
        }
      )

      // useEffect returns an optional cleanup function (equivalent to self.onUnmount)
      Some(
        () => {
          RescriptReactRouter.unwatchUrl(watcherId)
        },
      )
    })

    <div className="App">
      <FolderNavigation
        onClick={(folder, _event) => send(ShowRoute(ConversationList(folder)))}
        active_folder=state.active_folder
        counter={filter_conversations(list{}, state.conversations, "")}
      />
      <div className="ConversationListView" ref={ReactDOM.Ref.domRef(mainRef)}>
        <ConversationList
          folder=state.active_folder
          loading=state.loading_conversations
          current_conversation=state.current_conversation
          conversations={filter_conversations(
            state.interacted_with_conversations,
            state.conversations,
            state.filter_text,
            state.active_folder,
          )}
          selected_conversations=state.selected_conversations
          onClick={(conversation, _event) => send(ShowConversation(conversation))}
          onFilterTextChange={event =>
            send(FilterTextChanged((event->ReactEvent.Form.target)["value"]))}
          onRating={(conversation, rating, _event) =>
            send(SetConversationRating(conversation, rating))}
          onTrash={(conversation, trash, _event) => send(SetConversationTrash(conversation, trash))}
          onReadStatus={(conversation, is_read, _event) =>
            send(SetConversationReadStatus(conversation, is_read))}
          onToggle={conversation => send(ToggleConversation(conversation))}
          onSelectAll={_conversation => send(SelectOrUnselectAllConversations(true))}
          onMassReply={_event => send(ShowRoute(MassReply))}
          onMassTrash={_event => {
            open Utils
            send(
              SetMassTrash(
                array_filter(
                  (c: conversation) => element_in_list(c.id, state.selected_conversations),
                  state.conversations,
                ),
              ),
            )
          }}
          isFiltered={String.length(state.filter_text) > 0}
          hasAnyConversations={Array.length(state.conversations) > 0}
        />
      </div>
      <div className="MessageListView">
        {switch state.route {
        | Conversation =>
          switch state.current_conversation {
          | Some(conversation) =>
            <Conversation
              key={conversation.id |> string_of_int}
              conversation
              loading=state.loading_messages
              messages={state.current_conversation_messages |> Array.of_list}
              onRating={(conversation, rating, _event) =>
                send(SetConversationRating(conversation, rating))}
              onTrash={(conversation, trash, _event) =>
                send(SetConversationTrash(conversation, trash))}
              onReadStatus={(conversation, is_read, _event) =>
                send(SetConversationReadStatus(conversation, is_read))}
              onReplySent={(reply: message) => send(ReplyToConversation(conversation, reply))}
              onIgnore={conversation => send(SetConversationIgnore(conversation, true))}
              onSaveNotes={(conversation, notes) =>
                send(SaveConversationNotes(conversation, notes))}
              onBack={_event => send(ShowRoute(ConversationList(state.active_folder)))}
            />
          | _ => <div> {React.string("Invalid current_conversation")} </div>
          }
        | MassReply =>
          open Utils
          <MassReply
            conversations={array_filter(
              (c: conversation) => element_in_list(c.id, state.selected_conversations),
              state.conversations,
            )}
            onMassReplySent={(conversations, message_text, attachments, cbFunc) =>
              send(SendMassReply(conversations, message_text, attachments, cbFunc))}
          />
        | ConversationList(_) => <div />
        }}
      </div>
    </div>
  }
}

let default = immobilie_id => {
  switch ReactDOM.querySelector("#root") {
  | Some(root) => ReactDOM.render(<App immobilie_id />, root)
  | None => () // do nothing
  }
}
