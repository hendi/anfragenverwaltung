@val external process: 'a = "process"

@val external vite_api_url: string = "import.meta.env.VITE_API_URL"

let apiBaseUrl = vite_api_url

type rating =
  | @as("green") Green
  | @as("yellow") Yellow
  | @as("red") Red
  | @as("") Unrated

module Folder = {
  type t =
    | All
    | New
    | ByRating(rating)
    | Unreplied
    | Replied
    | Trash
}

type message_type =
  | @as("incoming") Incoming
  | @as("outgoing") Outgoing

@@warning("-30")
type rec conversation = {
  id: int,
  immobilie_id: int,
  name: string,
  email: string,
  phone: Js.Nullable.t<string>,
  street: Js.Nullable.t<string>,
  zipcode: Js.Nullable.t<string>,
  city: Js.Nullable.t<string>,
  source: string,
  priority: bool,
  shared_profile_link: Js.Nullable.t<string>,
  date_last_message: string,
  count_messages: int,
  latest_message: message,
  rating: rating,
  has_attachments: bool,
  notes: string,
  is_read: bool,
  is_ignored: bool,
  is_replied_to: bool,
  has_been_replied_to: bool,
  is_in_trash: bool,
}
and message = {
  id: int,
  conversation_id: int,
  @as("type") type_: message_type,
  content: string,
  date: string,
  attachments: array<attachment>,
}
and attachment = {
  filename: string,
  mimetype: string,
  url: string,
}

module Decode = {

  /** Unsafely coerces a backend json payload for a conversation. */
  external single_conversation: Js.Json.t => conversation = "%identity"

  /** Unsafely coerces a backend json payload for an array of conversations. */
  external many_conversations: Js.Json.t => array<conversation> = "%identity"

  /** Unsafely coerces a backend json payload for a message. */
  external single_message: Js.Json.t => message = "%identity"

  /** Unsafely coerces a backend json payload for an array of messages. */
  external many_messages: Js.Json.t => array<message> = "%identity"
}

let fetchConversations = async (immobilie_id): array<conversation> => {
  open Fetch

  let data = await fetch(
    `${apiBaseUrl}/anfragen/immobilie/${Belt.Int.toString(immobilie_id)}/conversations`,
    {
      credentials: #"include",
    },
  )->Promise.then(Response.json)

  Decode.many_conversations(data)
}

let fetchMessages = async (~conversationId: int, ~immobilieId: int): array<message> => {
  open Fetch

  let data = await fetch(
    `${apiBaseUrl}/anfragen/immobilie/${Belt.Int.toString(
        immobilieId,
      )}/conversations/${Belt.Int.toString(conversationId)}/messages`,
    {
      credentials: #"include",
    },
  )->Promise.then(Response.json)

  Decode.many_messages(data)
}

/*
 let fetchXXXMessages = (immobilie_id, callback) =>
   Js.Promise.(
     Fetch.fetchWithInit(
       apiBaseUrl
       ++ "/anfragen/immobilie/"
       ++ string_of_int(immobilie_id)
       ++ "/xxx-messages",
       Fetch.RequestInit.make(~credentials=Include, ()),
     )
     |> then_(Fetch.Response.json)
     |> then_(json =>
          json
          |> Decode.messages
          |> (
            messages => {
              callback(messages);
              resolve();
            }
          )
        )
     |> ignore
   );

 let fetchConversationMessages = (immobilie_id, conversation_id, callback) =>
   Js.Promise.(
     Fetch.fetchWithInit(
       apiBaseUrl
       ++ "/anfragen/immobilie/"
       ++ string_of_int(immobilie_id)
       ++ "/conversations/"
       ++ string_of_int(conversation_id)
       ++ "/messages",
       Fetch.RequestInit.make(~credentials=Include, ()),
     )
     |> then_(Fetch.Response.json)
     |> then_(json =>
          json
          |> Decode.messages
          |> (
            messages => {
              callback(messages);
              resolve();
            }
          )
        )
     |> ignore
   );
 */
let postReply = async (
  conversation: conversation,
  msg: string,
  attachments: array<string>,
): message => {
  open Fetch

  let dict = Dict.fromArray([
    ("message", Js.Json.string(msg)),
    ("attachments", Js.Json.stringArray(attachments)),
  ])

  let data = await fetch(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (Belt.Int.toString(conversation.immobilie_id) ++
    ("/conversations/" ++
    (Belt.Int.toString(conversation.id) ++ "/reply")))),
    {
      credentials: #"include",
      method: #POST,
      body: dict->Js.Json.stringifyAny->Option.getExn->Body.string,
    },
  )->Promise.then(Response.json)

  Decode.single_message(data)
}

let postMassReply = async (
  immobilie_id,
  conversations: array<conversation>,
  message_text,
  attachments: array<string>,
): unit => {
  let dict = Dict.fromArray([
    (
      "conversation_ids",
      conversations->Array.map(c => Belt.Float.fromInt(c.id)->Js.Json.number)->Js.Json.array,
    ),
    ("message", Js.Json.string(message_text)),
    ("attachments", Js.Json.stringArray(attachments)),
  ])

  open Fetch

  let _ = await fetch(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (Belt.Int.toString(immobilie_id) ++ "/massreply")),
    {
      credentials: #"include",
      method: #POST,
      body: dict->Js.Json.stringifyAny->Option.getExn->Body.string,
    },
  )
}

let postMassTrash = async (immobilie_id, conversationIds: array<int>): Js.Json.t => {
  let dict = Dict.fromArray([
    (
      "conversation_ids",
      conversationIds->Array.map(cid => Belt.Float.fromInt(cid)->Js.Json.number)->Js.Json.array,
    ),
  ])
  open Fetch

  await fetch(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (Belt.Int.toString(immobilie_id) ++ "/masstrash")),
    {
      credentials: #"include",
      method: #POST,
      body: dict->Js.Json.stringifyAny->Option.getExn->Body.string,
    },
  )->Promise.then(Response.json)
}

let updateConversation = async (
  ~id: int,
  ~immobilieId: int,
  data: Js.Dict.t<Js.Json.t>,
): conversation => {
  open Fetch

  let response = await fetch(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (Belt.Int.toString(immobilieId) ++ ("/conversations/" ++ Belt.Int.toString(id)))),
    {
      credentials: #"include",
      method: #POST,
      body: data->Js.Json.stringifyAny->Option.getExn->Body.string,
    },
  )->Promise.then(Response.json)

  Decode.single_conversation(response)
}

let rateConversation = (conversation: conversation, rating: rating) => {
  let data = Js.Dict.empty()
  Js.Dict.set(
    data,
    "rating",
    switch rating {
    | Green => Js.Json.string("green")
    | Yellow => Js.Json.string("yellow")
    | Red => Js.Json.string("red")
    | Unrated => Js.Json.string("")
    },
  )
  updateConversation(~id=conversation.id, ~immobilieId=conversation.immobilie_id, data)
}

let setReadStatusForConversation = (conversation: conversation, is_read: bool) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, "is_read", Js.Json.boolean(is_read))
  updateConversation(~id=conversation.id, ~immobilieId=conversation.immobilie_id, data)
}

let storeNotesForConversation = (conversation: conversation, notes: string) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, "notes", Js.Json.string(notes))
  updateConversation(~id=conversation.id, ~immobilieId=conversation.immobilie_id, data)
}

let updateTrashConversation = (conversation: conversation, is_in_trash: bool) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, is_in_trash ? "trash" : "untrash", Js.Json.string("x"))
  updateConversation(~id=conversation.id, ~immobilieId=conversation.immobilie_id, data)
}

let ignoreConversation = (~id: int, ~immobilieId: int, isIgnored: bool) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, isIgnored ? "ignore" : "unignore", Js.Json.string("x"))
  updateConversation(~id, ~immobilieId, data)
}
