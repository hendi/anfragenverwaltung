%%raw(`import './app.css'`)

@@warning("-3")

open Belt.Option

open ConversationData
let filterConversations = (
  interactedWithConversations: list<int>,
  conversations: array<conversation>,
  filterText: string,
  folder: Folder.t,
): array<conversation> => {
  let conversations =
    filterText === ""
      ? conversations
      : conversations->Js.Array2.filter(c =>
          if filterText == "" {
            true
          } else {
            open Utils
            string_contains(c.name |> String.lowercase, filterText) ||
            (string_contains(c.email |> String.lowercase, filterText) ||
            (string_contains(c.phone->getWithDefault("") |> String.lowercase, filterText) ||
            (string_contains(c.city->getWithDefault("") |> String.lowercase, filterText) ||
            (string_contains(c.zipcode->getWithDefault("") |> String.lowercase, filterText) ||
            (string_contains(c.street->getWithDefault("") |> String.lowercase, filterText) ||
            (string_contains(c.latest_message.content |> String.lowercase, filterText) ||
            string_contains(c.notes, filterText)))))))
          }
        )

  switch folder {
  | All =>
    conversations->Js.Array2.filter(c =>
      !c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interactedWithConversations)
    )
  | New =>
    conversations->Js.Array2.filter((c: conversation) =>
      (!c.is_in_trash && (c.rating == Unrated && (!c.is_replied_to && !c.is_ignored))) ||
        ((!c.is_in_trash && !c.is_read) ||
        List.exists((c_id: int) => c_id == c.id, interactedWithConversations))
    )
  | ByRating(rating) =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.rating == rating) ||
        List.exists((c_id: int) => c_id == c.id, interactedWithConversations)
    )
  | Unreplied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && (!c.is_replied_to && !c.is_ignored)) ||
        List.exists((c_id: int) => c_id == c.id, interactedWithConversations)
    )
  | Replied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.has_been_replied_to) ||
        List.exists((c_id: int) => c_id == c.id, interactedWithConversations)
    )
  | Trash =>
    conversations->Js.Array2.filter(c =>
      c.is_in_trash || List.exists((c_id: int) => c_id == c.id, interactedWithConversations)
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

  let useUpdateConversationNotes = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (conversation, string)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

          client->ReactQuery.Client.setQueryData(queryKey, conversation)

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
      (params: (conversation, string)) => {
        let (conversation, notes) = params
        storeNotesForConversation(conversation, notes)
      },
    )

    mutation
  }

  let useUpdateTrashMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (conversation, bool)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

          client->ReactQuery.Client.setQueryData(queryKey, conversation)

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
      (params: (conversation, bool)) => {
        let (conversation, isTrash) = params
        updateTrashConversation(conversation, isTrash)
      },
    )

    mutation
  }

  let useTrashAllMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (int, array<int>)) => {
        let (_immobilieId, conversationIds) = params
        let queryKey = #conversation

        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConvs: option<array<conversation>> =
            client->ReactQuery.Client.getQueryData(queryKey)

          let newConversations = previousConvs->Belt.Option.map(previousConvs => {
            previousConvs->Belt.Array.map((conv: conversation) => {
              {...conv, is_in_trash: true}
            })
          })

          client->ReactQuery.Client.setQueryData(queryKey, newConversations)

          () => {
            client->ReactQuery.Client.setQueryData(queryKey, previousConvs)
          }
        })
      },
      ~onError=(_err, _params, cleanup) => {
        cleanup()
      },
      ~onSettled=(_data, _err, _params, _context) => {
        client->ReactQuery.Client.invalidateQueries(#conversation)
      },
      (params: (int, array<int>)) => {
        let (immobilieId, conversationIds) = params
        postMassTrash(immobilieId, conversationIds)
      },
    )

    mutation
  }

  let useSendReplyMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=(params: (conversation, string, array<string>)) => {
        let (conversation, _, _) = params

        let queryKey = (#conversation, conversation.id)
        client
        ->ReactQuery.Client.cancelQueries(queryKey)
        ->Promise2.thenResolve(() => {
          let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

          client->ReactQuery.Client.setQueryData(queryKey, conversation)

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
      (params: (conversation, string, array<string>)) => {
        let (conversation, msg, attachments) = params
        postReply(conversation, msg, attachments)
      },
    )

    mutation
  }
}

type state = {
  filterText: string,
  conversations: array<conversation>,
  interactedWithConversations: list<int>,
  selected_conversations: list<int>, // list of conversation ids
}

type action =
  | ShowRoute(Route.t)
  | SetConversationIgnore(conversation, bool)
  | SelectOrUnselectConversation(int)
  | SelectOrUnselectAllConversations(bool)
  | SendMassReply(array<conversation>, string, array<string>, string => int)
  | FilterTextChanged(string)

let initialState = {
  conversations: [],
  interactedWithConversations: list{},
  selected_conversations: list{},
  filterText: "",
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
  let updateConversationNotesMutation = Hooks.useUpdateConversationNotes(client)
  let updateTrashConversationMutation = Hooks.useUpdateTrashMutation(client)
  let postReplyMutation = Hooks.useSendReplyMutation(client)
  let trashAllMutation = Hooks.useTrashAllMutation(client)

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
        filterText: text->Js.String2.trim->Js.String2.toLowerCase,
      })
    | ShowRoute(newRoute) =>
      let selected_conversations = if newRoute != route {
        list{}
      } else {
        state.selected_conversations
      }
      // TODO: Add back the original scrollToTop behavior
      ReactUpdate.UpdateWithSideEffects(
        {...state, selected_conversations: selected_conversations},
        _self => {
          newRoute->Route.toUrl->RescriptReactRouter.push
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
    | SelectOrUnselectConversation(conversationId) =>
      let newSelectedConversations = if (
        !Belt.List.some(state.selected_conversations, convId => convId === conversationId)
      ) {
        list{conversationId, ...state.selected_conversations}
      } else {
        Belt.List.filter(state.selected_conversations, convId => convId != conversationId)
      }

      ReactUpdate.Update({...state, selected_conversations: newSelectedConversations})
    | SelectOrUnselectAllConversations(selected) =>
      let selected_conversations = selected
        ? Array.map(
            (c: conversation) => c.id,
            filterConversations(list{}, conversations, state.filterText, activeFolder),
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

  let onSaveNotes = (conversation: conversation, notes: string) => {
    updateConversationNotesMutation(. (conversation, notes))
  }

  let onTrash = (conversation, isTrash) => {
    updateTrashConversationMutation(. (conversation, isTrash))
  }

  let onMassTrash = () => {
    let conversationIds = state.selected_conversations->Belt.List.toArray
    trashAllMutation(. (immobilieId, conversationIds))
  }

  let onReplySend = (conversation, messageText, attachments) => {
    Js.log3("onSendReply for ", conversation, messageText)
    postReplyMutation(. (conversation, messageText, attachments))
  }

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
          conversations={filterConversations(
            state.interactedWithConversations,
            conversations,
            state.filterText,
            activeFolder,
          )}
          selectedConversations=state.selected_conversations
          onConversationClick={(conversation: conversation) =>
            send(ShowRoute(Route.Conversation(conversation.id)))}
          onFilterTextChange={event =>
            send(FilterTextChanged((event->ReactEvent.Form.target)["value"]))}
          onRating
          onTrash
          onReadStatus
          onToggleSelect={(conversation: ConversationData.conversation) =>
            send(SelectOrUnselectConversation(conversation.id))}
          onToggleSelectAll={selected => send(SelectOrUnselectAllConversations(selected))}
          onMassReply={_event => send(ShowRoute(MassReply))}
          onMassTrash
          isFiltered={String.length(state.filterText) > 0}
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
            let isLoadingMessages = switch currentMessagesQuery {
            | Loading => true
            | _ => false
            }
            <Conversation
              key={conversation.id |> string_of_int}
              conversation
              loading=isLoadingMessages
              messages={currentMessages}
              onRating
              onTrash
              onReadStatus
              onReplySend
              onIgnore={conversation => send(SetConversationIgnore(conversation, true))}
              onSaveNotes
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
