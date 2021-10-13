%%raw(`import './app.css'`)

@@warning("-3")

open Belt.Option

open ConversationData
let filter_conversations = (
  interacted_with_conversations: list<int>,
  conversations: array<conversation>,
  filter_text: string,
  folder: Folder.t,
): array<conversation> => {
  let conversations =
    filter_text === ""
      ? conversations
      : conversations->Js.Array2.filter(c =>
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

  switch folder {
  | All =>
    conversations->Js.Array2.filter(c =>
      !c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
    )
  | New =>
    conversations->Js.Array2.filter((c: conversation) =>
      (!c.is_in_trash && (c.rating == Unrated && (!c.is_replied_to && !c.is_ignored))) ||
        ((!c.is_in_trash && !c.is_read) ||
        List.exists((c_id: int) => c_id == c.id, interacted_with_conversations))
    )
  | ByRating(rating) =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.rating == rating) ||
        List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
    )
  | Unreplied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && (!c.is_replied_to && !c.is_ignored)) ||
        List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
    )
  | Replied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.has_been_replied_to) ||
        List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
    )
  | Trash =>
    conversations->Js.Array2.filter(c =>
      c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interacted_with_conversations)
    )
  }
}

module Route = {
  type t =
    | ConversationList(Folder.t)
    | Conversation(int)
    | MassReply
    | Unknown404

  let fromUrlPath = (path: list<string>): t => {
    switch path {
    | list{} => ConversationList(New)
    | list{"conversation", id} =>
      switch Belt.Int.fromString(id) {
      | Some(id) => Conversation(id)
      | None => Unknown404
      }
    | list{"folder", str} =>
      let folder = switch str {
      | "all" => Folder.All->Some
      | "new" => New->Some
      | "unreplied" => Unreplied->Some
      | "replied" => Replied->Some
      | "trash" => Trash->Some
      | _ => None
      }

      switch folder {
      | None => Unknown404
      | Some(folder) => ConversationList(folder)
      }
    | list{"folder", "by-rating", str} =>
      let folder = switch str {
      | "favorite" => Folder.ByRating(Green)
      | "maybe" => ByRating(Yellow)
      | "uninteresting" => ByRating(Red)
      | "unrated"
      | _ =>
        ByRating(Unrated)
      }

      ConversationList(folder)
    | _ => Unknown404
    }
  }

  let toUrl = route => {
    switch route {
    | Unknown404 => "/not-found"
    | Conversation(id) => "/conversation/" ++ Belt.Int.toString(id)
    | MassReply => "/mass-reply"
    | ConversationList(folder) =>
      let folderStr = switch folder {
      | All => "all"
      | New => "new"
      | Unreplied => "unreplied"
      | Replied => "replied"
      | Trash => "trash"
      | ByRating(rating) =>
        "by-rating" ++
        switch rating {
        | Unrated => "/unrated"
        | Green => "/favorite"
        | Yellow => "/maybe"
        | Red => "/uninteresting"
        }
      }

      `/folder/${folderStr}`
    }
  }
}

module Hooks = {
  let useMarkConversationAsReadMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (conversation, bool)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

          client->ReactQuery.Client.setQueryData(queryKey, conversation)

          // return "rollback function" as context
          () => {
            client->ReactQuery.Client.setQueryData(queryKey, previousConv)
          }
        })
      },
      ~onError=(_err, _params, cleanup) => {
        cleanup()
      },
      ~onSettled=(_data, _err, _params, _context) => {
        client->ReactQuery.Client.invalidateQueries(#conversation)
      },
      params => {
        let (conversation, isRead) = params
        setReadStatusForConversation(conversation, isRead)
      },
    )
    mutation
  }

  let useRateConversationMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (conversation, rating)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

          client->ReactQuery.Client.setQueryData(queryKey, conversation)

          // return "rollback function" as context
          () => {
            client->ReactQuery.Client.setQueryData(queryKey, previousConv)
          }
        })
      },
      ~onError=(_err, _params, cleanup) => {
        cleanup()
      },
      ~onSettled=(_data, _err, _params, _context) => {
        client->ReactQuery.Client.invalidateQueries(#conversation)
      },
      params => {
        let (conversation, rating) = params
        rateConversation(conversation, rating)
      },
    )
    mutation
  }
}

module App = {
  type state = {
    filter_text: string,
    loading_conversations: bool,
    conversations: array<conversation>,
    loading_messages: bool,
    interacted_with_conversations: list<int>,
    selected_conversations: list<int>,
  }

  type action =
    | ShowRoute(Route.t)
    | LoadedConversationMessages(array<message>)
    | SetConversationRating(conversation, rating)
    | SetConversationTrash(conversation, bool)
    | SetConversationReadStatus(conversation, bool)
    | SetConversationIgnore(conversation, bool)
    | ToggleConversation(conversation)
    | SelectOrUnselectAllConversations(bool)
    | ReplyToConversation(conversation, message)
    | SendMassReply(array<conversation>, string, array<string>, string => int)
    | SetMassTrash(array<conversation>)
    | SaveConversationNotes(conversation, string)
    | FilterTextChanged(string)

  let initialState = {
    loading_conversations: true,
    conversations: [],
    loading_messages: false,
    interacted_with_conversations: list{},
    selected_conversations: list{},
    filter_text: "",
  }

  @react.component
  let make = (~immobilieId: int) => {
    let mainRef = React.useRef(Js.Nullable.null)

    let url = RescriptReactRouter.useUrl()
    let route = Route.fromUrlPath(url.path)

    let client = ReactQuery.Client.useQueryClient()

    React.useEffect0(() => {
      Route.toUrl(route)->RescriptReactRouter.replace
      None
    })

    let conversationsQuery = Query.useQuery(~resource=#conversation, ~params=(), _ => {
      ConversationData.fetchConversations(immobilieId)
    })

    let conversations = switch conversationsQuery {
    | Success(convs) => convs
    | _ => []
    }

    let currentConversation = switch route {
    | Conversation(id) =>
      let currentConversation = Js.Array2.find(conversations, conv => {
        conv.id == id
      })
      currentConversation
    | _ => None
    }

    let currentMessagesQuery = Query.useDependentQuery(
      ~resource=#message,
      ~params=currentConversation,
      conversation => {
        ConversationData.fetchMessages(
          ~conversationId=conversation.id,
          ~immobilieId=conversation.immobilie_id,
        )
      },
    )

    let currentMessages = switch currentMessagesQuery {
    | Success(messages) => messages
    | _ => []
    }

    let rateConversationMutation = Hooks.useRateConversationMutation(client)
    let markConversationAsReadMutation = Hooks.useMarkConversationAsReadMutation(client)

    let activeFolder = switch route {
    | ConversationList(folder) => folder
    | Conversation(id) =>
      let found = conversations->Js.Array2.find(conv => {
        conv.id == id
      })
      switch found {
      | Some(conv) => ByRating(conv.rating)
      | None => New
      }
    | _ => New
    }

    let (state, send) = ReactUpdate.useReducer((state, action) =>
      switch action {
      | FilterTextChanged(text) =>
        ReactUpdate.Update({
          ...state,
          filter_text: text->Js.String2.trim->Js.String2.toLowerCase,
        })
      | ShowRoute(route) =>
        // TODO: Add back the original scrollToTop behavior
        ReactUpdate.UpdateWithSideEffects(
          state,
          _self => {
            route->Route.toUrl->RescriptReactRouter.push
            None
          },
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
          },
          _self => {
            /* storeNotesForConversation(conversation, notes, _ => ()) */
            None
          },
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
            interacted_with_conversations: List.append(
              state.interacted_with_conversations,
              list{conversation.id},
            ),
          },
          _self => {
            /* trashConversation(conversation, is_in_trash, _ => ()) */
            None
          },
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
          },
          _self => {
            /* ignoreConversation(conversation, is_ignored, _ => ()) */
            None
          },
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
          },
          _self => {
            postMassReply(immobilieId, conversations, message_text, attachments, _ =>
              cbFunc("")->ignore
            )
            None
          },
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
          _self => {
            postMassTrash(immobilieId, conversations)
            None
          },
        )
      | LoadedConversationMessages(_messages) =>
        ReactUpdate.Update({
          ...state,
          loading_messages: false,
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
              filter_conversations(list{}, state.conversations, state.filter_text, activeFolder),
            )
          : []
        ReactUpdate.Update({
          ...state,
          selected_conversations: selected_conversations->Belt.List.fromArray,
        })
      | _ => ReactUpdate.NoUpdate
      }
    , initialState)

    let onReadStatus = (conversation, isRead) =>
      markConversationAsReadMutation(. (conversation, isRead))

    let onRating = (conversation: conversation, rating, _event) =>
      rateConversationMutation(. (conversation, rating))

    <div>
      <ReactQueryDevtools position=#"bottom-right" />
      <div className="debug">
        {route->Route.toUrl->React.string}
        {switch conversationsQuery {
        | Loading => "loading conversations..."
        | Success(convs) => "Loaded conversations: " ++ Belt.Array.length(convs)->Belt.Int.toString
        | _ => ""
        }->React.string}
      </div>
      <div className="App">
        <FolderNavigation
          onFolderClick={folder => send(ShowRoute(ConversationList(folder)))}
          activeFolder
          conversations
        />
        <div className="ConversationListView" ref={ReactDOM.Ref.domRef(mainRef)}>
          <ConversationList
            folder=activeFolder
            loading={conversationsQuery == Loading}
            currentConversation
            conversations={filter_conversations(
              state.interacted_with_conversations,
              conversations,
              state.filter_text,
              activeFolder,
            )}
            selectedConversations=state.selected_conversations
            onConversationClick={(conversation: conversation) =>
              send(ShowRoute(Route.Conversation(conversation.id)))}
            onFilterTextChange={event =>
              send(FilterTextChanged((event->ReactEvent.Form.target)["value"]))}
            onRating
            onTrash={(conversation, trash, _event) =>
              send(SetConversationTrash(conversation, trash))}
            onReadStatus
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
          {switch url.path {
          | list{"conversation", id} => <div> {React.string("Conversation id " ++ id)} </div>
          | _ => React.null
          }}
          {switch route {
          | Unknown404 => <div> {React.string("404 not found")} </div>
          | Conversation(_id) =>
            switch currentConversation {
            | Some(conversation) =>
              <Conversation
                key={conversation.id |> string_of_int}
                conversation
                loading=state.loading_messages
                messages={currentMessages}
                onRating
                onTrash={(conversation, trash, _event) =>
                  send(SetConversationTrash(conversation, trash))}
                onReadStatus
                onReplySent={(reply: message) => send(ReplyToConversation(conversation, reply))}
                onIgnore={conversation => send(SetConversationIgnore(conversation, true))}
                onSaveNotes={(conversation, notes) =>
                  send(SaveConversationNotes(conversation, notes))}
                onBack={_event => send(ShowRoute(ConversationList(activeFolder)))}
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
    </div>
  }
}
