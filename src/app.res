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
            string_contains(String.toLowerCase(c.name), filterText) ||
            (string_contains(String.toLowerCase(c.email), filterText) ||
            (string_contains(String.toLowerCase(c.phone->getWithDefault("")), filterText) ||
            (string_contains(String.toLowerCase(c.city->getWithDefault("")), filterText) ||
            (string_contains(String.toLowerCase(c.zipcode->getWithDefault("")), filterText) ||
            (string_contains(String.toLowerCase(c.street->getWithDefault("")), filterText) ||
            (string_contains(String.toLowerCase(c.latest_message.content), filterText) ||
            string_contains(c.notes, filterText)))))))
          }
        )

  switch folder {
  | All =>
    conversations->Js.Array2.filter(c =>
      !c.is_in_trash || interactedWithConversations->List.has(c.id, (a, b) => a == b)
    )
  | New =>
    conversations->Js.Array2.filter((c: conversation) =>
      (!c.is_in_trash && (c.rating == Unrated && (!c.is_replied_to && !c.is_ignored))) ||
        ((!c.is_in_trash && !c.is_read) ||
        interactedWithConversations->List.has(c.id, (a, b) => a == b))
    )
  | ByRating(rating) =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.rating == rating) ||
        interactedWithConversations->List.has(c.id, (a, b) => a == b)
    )
  | Unreplied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && (!c.is_replied_to && !c.is_ignored)) ||
        interactedWithConversations->List.has(c.id, (a, b) => a == b)
    )
  | Replied =>
    conversations->Js.Array2.filter(c =>
      (!c.is_in_trash && c.has_been_replied_to) ||
        interactedWithConversations->List.has(c.id, (a, b) => a == b)
    )
  | Trash =>
    conversations->Js.Array2.filter(c =>
      c.is_in_trash || interactedWithConversations->List.has(c.id, (a, b) => a == b)
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
    | list{"mass-reply"} => MassReply
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
      ~onMutate=async (params: (conversation, bool)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)

        await client->ReactQuery.Client.cancelQueries(queryKey)

        let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

        client->ReactQuery.Client.setQueryData(queryKey, conversation)

        // return "rollback function" as context
        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConv)
        }
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
      ~onMutate=async (params: (conversation, rating)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)

        await client->ReactQuery.Client.cancelQueries(queryKey)
        let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

        client->ReactQuery.Client.setQueryData(queryKey, conversation)

        // return "rollback function" as context
        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConv)
        }
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
      ~onMutate=async (params: (conversation, string)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        await client->ReactQuery.Client.cancelQueries(queryKey)
        let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

        client->ReactQuery.Client.setQueryData(queryKey, conversation)

        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConv)
        }
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
      ~onMutate=async (params: (conversation, bool)) => {
        let (conversation, _) = params

        let queryKey = (#conversation, conversation.id)
        await client->ReactQuery.Client.cancelQueries(queryKey)
        let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

        client->ReactQuery.Client.setQueryData(queryKey, conversation)

        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConv)
        }
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
      ~onMutate=async (params: (int, array<int>)) => {
        let (_immobilieId, _conversationIds) = params
        let queryKey = #conversation

        await client->ReactQuery.Client.cancelQueries(queryKey)
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

  let useIgnoreConversationMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=async (params: (int, int, bool)) => {
        let (conversationId, _immobilieId, isIgnored) = params

        let queryKey = #conversation
        await client->ReactQuery.Client.cancelQueries(queryKey)

        let previousConvs: option<array<conversation>> =
          client->ReactQuery.Client.getQueryData(queryKey)

        let newConversations = previousConvs->Belt.Option.map(previousConvs => {
          previousConvs->Belt.Array.map((conv: conversation) => {
            if conv.id == conversationId {
              {...conv, is_ignored: isIgnored}
            } else {
              conv
            }
          })
        })

        client->ReactQuery.Client.setQueryData(queryKey, newConversations)

        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConvs)
        }
      },
      ~onError=(_err, _params, cleanup) => {
        cleanup()
      },
      ~onSettled=(_data, _err, _params, _context) => {
        client->ReactQuery.Client.invalidateQueries(#conversation)
      },
      (params: (int, int, bool)) => {
        let (conversationId, immobilieId, isIgnored) = params
        ignoreConversation(~id=conversationId, ~immobilieId, isIgnored)
      },
    )

    mutation
  }

  let useSendReplyMutation = client => {
    let (_, mutation) = Query.useMutation(
      ~onMutate=async (params: (conversation, string, array<string>)) => {
        let (conversation, _, _) = params

        let queryKey = (#conversation, conversation.id)

        await client->ReactQuery.Client.cancelQueries(queryKey)

        let previousConv = client->ReactQuery.Client.getQueryData(queryKey)

        client->ReactQuery.Client.setQueryData(queryKey, conversation)

        () => {
          client->ReactQuery.Client.setQueryData(queryKey, previousConv)
        }
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
  | SelectOrUnselectConversation(int)
  | SelectOrUnselectAllConversations(bool)
  | SendMassReply(array<conversation>, string, array<string>, string => int)
  | FilterTextChanged(string)
  | ResetInteractedList(list<int>)
  | UpdateInteractedList(int)

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
  let ignoreConversationMutation = Hooks.useIgnoreConversationMutation(client)

  let (activeFolder, setActiveFolder) = React.useState(() => {
    switch route {
    | ConversationList(folder) => folder
    | _ => New
    }
  })

  let (state, send) = ReactUpdate.useReducer((state, action) =>
    switch action {
    | FilterTextChanged(text) =>
      ReactUpdate.Update({
        ...state,
        filterText: text->Js.String2.trim->Js.String2.toLowerCase,
      })
    | ResetInteractedList(newList) =>
      ReactUpdate.Update({
        ...state,
        selected_conversations: list{},
        interactedWithConversations: newList,
      })
    | UpdateInteractedList(conversationId) =>
      ReactUpdate.Update({
        ...state,
        interactedWithConversations: List.add(state.interactedWithConversations, conversationId),
      })
    | ShowRoute(newRoute) =>
       /*
      let selected_conversations = if newRoute != route {
        list{}
      } else {
        state.selected_conversations
      }
      */
      // TODO: Add back the original scrollToTop behavior
      ReactUpdate.UpdateWithSideEffects(
        {state},
        _self => {
          newRoute->Route.toUrl->RescriptReactRouter.push

          switch newRoute {
          | ConversationList(folder) => setActiveFolder(_ => folder)
          | _ => ()
          }
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
          conversations: state.conversations->Array.map((c: conversation): conversation =>
            if conversations->Array.find(conv => conv.id == c.id) != None {
              {
                ...c,
                count_messages: c.count_messages + 1,
                is_replied_to: true,
                is_read: true,
              }
            } else {
              c
            }
          ),
        },
        _self => {
          postMassReply(immobilieId, conversations, message_text, attachments)
          ->Promise.then(() => {
            cbFunc("")->ignore
            Promise.resolve()
          })
          ->ignore
          None
        },
      )
    | SelectOrUnselectConversation(conversationId) =>
      let newSelectedConversations = if (
        !Belt.List.some(state.selected_conversations, convId => convId === conversationId)
      ) {
        list{conversationId, ...state.selected_conversations}
      } else {
        Belt.List.filter(state.selected_conversations, convId => convId !== conversationId)
      }
      ReactUpdate.Update({...state, selected_conversations: newSelectedConversations})
    | SelectOrUnselectAllConversations(selected) =>
      let selected_conversations = selected
        ? filterConversations(
            list{},
            conversations,
            state.filterText,
            activeFolder,
          )->Array.map((c: conversation) => c.id)
        : []

      ReactUpdate.Update({
        ...state,
        selected_conversations: selected_conversations->Belt.List.fromArray,
      })
    }
  , initialState)

  React.useEffect1(() => {
    switch currentConversation {
    | Some(currentConversation) =>
      send(UpdateInteractedList(currentConversation.id))
    | None => ()
    }
    None
  }, [currentConversation])

  React.useEffect1(() => {
    send(ResetInteractedList(list{}))
    None
  }, [activeFolder])

  let onReadStatus = (conversation, isRead) =>
    markConversationAsReadMutation((conversation, isRead))

  let onRating = (conversation: conversation, rating, _event) =>
    rateConversationMutation((conversation, rating))

  let onSaveNotes = (conversation: conversation, notes: string) => {
    updateConversationNotesMutation((conversation, notes))
  }

  let onTrash = (conversation, isTrash) => {
    updateTrashConversationMutation((conversation, isTrash))
  }

  let onMassTrash = () => {
    let conversationIds = state.selected_conversations->Belt.List.toArray
    trashAllMutation((immobilieId, conversationIds))
  }

  let onReplySend = (conversation, messageText, attachments) => {
    postReplyMutation((conversation, messageText, attachments))
  }

  <div>
    <ReactQueryDevtools position=#"bottom-right" />
    <div className="grid grid-cols-12 gap-4 bg-slate-50">
      <FolderNavigation
        onFolderClick={folder => send(ShowRoute(ConversationList(folder)))}
        activeFolder
        conversations
      />
      <div className="col-span-3" ref={ReactDOM.Ref.domRef(mainRef)}>
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
          onConversationClick={(conversation: conversation) => {
            onReadStatus(conversation,true)
            send(ShowRoute(Route.Conversation(conversation.id)))}
          }
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
      <div className="col-span-7">
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
              key={string_of_int(conversation.id)}
              conversation
              loading=isLoadingMessages
              messages={currentMessages}
              onRating
              onTrash
              onReadStatus
              onReplySend
              onIgnore={() => {
                ignoreConversationMutation((conversation.id, immobilieId, true))
              }}
              onSaveNotes
              onBack={_event => send(ShowRoute(ConversationList(activeFolder)))}
            />
          | _ => <div> {React.string("Invalid current_conversation")} </div>
          }
        | MassReply =>
          open Utils
          let filteredConversations = conversations->Array.filter(conversation => element_in_list(conversation.id, state.selected_conversations));
          <MassReply
            conversations=filteredConversations
            onMassReplySent={(conversations, message_text, attachments, cbFunc) =>
              send(SendMassReply(conversations, message_text, attachments, cbFunc))}
          />
        | ConversationList(_) => <div />
        }}
      </div>
    </div>
  </div>
}
