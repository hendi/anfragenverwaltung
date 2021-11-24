@val external process: 'a = "process"

let apiBaseUrl = if process["env"]["NODE_ENV"] == "production" {
  ""
} else {
  "http://localhost:8001"
}

type rating =
  | Green
  | Yellow
  | Red
  | Unrated

module Folder = {
  type t =
    | All
    | New
    | ByRating(rating)
    | Unreplied
    | Replied
    | Trash
}

type type_ =
  | Incoming
  | Outgoing

@@warning("-30")
type rec conversation = {
  id: int,
  immobilie_id: int,
  name: string,
  email: string,
  phone: option<string>,
  street: option<string>,
  zipcode: option<string>,
  city: option<string>,
  source: string,
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
  type_: type_,
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
  let rec single_conversation = (json): conversation => {
    open Json.Decode
    {
      id: json |> field("id", int),
      immobilie_id: json |> field("immobilie_id", int),
      name: json |> field("name", string),
      email: json |> field("email", string),
      phone: json |> optional(field("phone", string)),
      street: json |> optional(field("street", string)),
      zipcode: json |> optional(field("zipcode", string)),
      city: json |> optional(field("city", string)),
      source: json |> field("source", string),
      date_last_message: json |> field("date_last_message", string),
      count_messages: json |> field("count_messages", int),
      latest_message: json |> field("latest_message", single_message),
      rating: json
      |> optional(field("rating", string))
      |> (
        rating =>
          switch rating {
          | Some("green") => Green
          | Some("yellow") => Yellow
          | Some("red") => Red
          | _ => Unrated
          }
      ),
      has_attachments: json |> field("has_attachments", bool),
      notes: json |> field("notes", string),
      is_read: json |> field("is_read", bool),
      is_ignored: json |> field("is_ignored", bool),
      is_replied_to: json |> field("is_replied_to", bool),
      has_been_replied_to: json |> field("has_been_replied_to", bool),
      is_in_trash: json |> field("is_in_trash", bool),
    }
  }
  and single_message = (json): message => {
    open Json.Decode
    {
      id: json |> field("id", int),
      /* conversation: json |> field("conversation", conversation), */
      conversation_id: json |> field("conversation_id", int),
      type_: json
      |> field("type", string)
      |> (
        type_ =>
          switch type_ {
          | "incoming" => Incoming
          | "outgoing" => Outgoing
          | _ => failwith("invalid message type")
          }
      ),
      content: json |> field("content", string),
      date: json |> field("date", string),
      attachments: json |> field("attachments", many_attachments),
    }
  }
  and single_attachment = (json): attachment => {
    open Json.Decode
    {
      filename: json |> field("filename", string),
      mimetype: json |> field("mimetype", string),
      url: json |> field("url", string),
    }
  }
  and many_conversations = json => json |> Json.Decode.array(single_conversation)
  and many_messages = (json): array<message> => json |> Json.Decode.array(single_message)
  and many_attachments = (json): array<attachment> => json |> Json.Decode.array(single_attachment)
}

let fetchConversations = (immobilie_id): Js.Promise.t<array<conversation>> => {
  open Promise2
  Fetch.fetchWithInit(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (string_of_int(immobilie_id) ++ "/conversations")),
    Fetch.RequestInit.make(~credentials=Include, ()),
  )
  ->then(Fetch.Response.json)
  ->then(json => json->Decode.many_conversations->resolve)
}

let fetchMessages = (~conversationId: int, ~immobilieId: int): Js.Promise.t<array<message>> => {
  open Promise2
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (Belt.Int.toString(immobilieId) ++
    ("/conversations/" ++
    (Belt.Int.toString(conversationId) ++ "/messages")))),
    Fetch.RequestInit.make(~credentials=Include, ()),
  )
  ->then(Fetch.Response.json)
  ->then(json => json->Decode.many_messages->resolve)
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
let postReply = (
  conversation: conversation,
  msg: string,
  attachments: array<string>,
): Js.Promise.t<message> => {
  let dict = Js.Dict.empty()
  Js.Dict.set(dict, "message", Js.Json.string(msg))
  Js.Dict.set(dict, "attachments", Js.Json.stringArray(attachments))
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (Belt.Int.toString(conversation.immobilie_id) ++
    ("/conversations/" ++
    (Belt.Int.toString(conversation.id) ++ "/reply")))),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(dict))),
      (),
    ),
  )
  ->Promise2.then(Fetch.Response.json)
  ->Promise2.thenResolve(json => json->Decode.single_message)
}

let postMassReply = (
  immobilie_id,
  conversations: array<conversation>,
  message_text,
  attachments: array<string>,
  callback,
) => {
  let json = {
    open Json.Encode
    object_(list{
      ("conversation_ids", array(int, Array.map(c => c.id, conversations))),
      ("message", string(message_text)),
      ("attachments", Js.Json.stringArray(attachments)),
    })
  } |> Js.Json.stringify
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (string_of_int(immobilie_id) ++ "/massreply")),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(json),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json => {
    callback(json)
    resolve()
  })
  |> ignore
}

let postMassTrash = (immobilie_id, conversations: array<conversation>) => {
  let json = {
    open Json.Encode
    object_(list{("conversation_ids", array(int, Array.map(c => c.id, conversations)))})
  } |> Js.Json.stringify
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (string_of_int(immobilie_id) ++ "/masstrash")),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(json),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(_json => resolve())
  |> ignore
}

let updateConversation = (~id: int, ~immobilieId: int, data: Js.Dict.t<Js.Json.t>): Js.Promise.t<
  conversation,
> => {
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (Belt.Int.toString(immobilieId) ++ ("/conversations/" ++ Belt.Int.toString(id)))),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(data))),
      (),
    ),
  )
  ->Promise2.then(Fetch.Response.json)
  ->Promise2.thenResolve(json => json->Decode.single_conversation)
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

let ignoreConversation = (conversation: conversation, is_ignored: bool) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, is_ignored ? "ignore" : "unignore", Js.Json.string("x"))
  updateConversation(~id=conversation.id, ~immobilieId=conversation.immobilie_id, data)
}
