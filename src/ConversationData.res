let isProd = true

let apiBaseUrl = if isProd {
  ""
} else {
  "http://localhost:8000"
}

type rating =
  | Green
  | Yellow
  | Red

type folder =
  | All
  | New
  | ByRating(option<rating>)
  | Unreplied
  | Replied
  | Trash

type type_ =
  | Incoming
  | Outgoing

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
  rating: option<rating>,
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
          | Some("green") => Some(Green)
          | Some("yellow") => Some(Yellow)
          | Some("red") => Some(Red)
          | _ => None
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

let fetchConversations = (immobilie_id, callback) => {
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++ ("/anfragen/immobilie/" ++ (string_of_int(immobilie_id) ++ "/conversations")),
    Fetch.RequestInit.make(~credentials=Include, ()),
  )
  |> then_(Fetch.Response.json)
  |> then_(json =>
    json
    |> Decode.many_conversations
    |> (
      conversations => {
        callback(conversations)
        resolve()
      }
    )
  )
  |> ignore
}

let fetchConversationMessages = (conversation: conversation, callback) => {
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (string_of_int(conversation.immobilie_id) ++
    ("/conversations/" ++
    (string_of_int(conversation.id) ++ "/messages")))),
    Fetch.RequestInit.make(~credentials=Include, ()),
  )
  |> then_(Fetch.Response.json)
  |> then_(json =>
    json
    |> Decode.many_messages
    |> (
      messages => {
        callback(messages)
        resolve()
      }
    )
  )
  |> ignore
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
  message_text: string,
  attachments: array<string>,
  callback,
) => {
  let dict = Js.Dict.empty()
  Js.Dict.set(dict, "message", Js.Json.string(message_text))
  Js.Dict.set(dict, "attachments", Js.Json.stringArray(attachments))
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (string_of_int(conversation.immobilie_id) ++
    ("/conversations/" ++
    (string_of_int(conversation.id) ++ "/reply")))),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(dict))),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json =>
    json
    |> Decode.single_message
    |> (
      message => {
        callback(message)
        resolve()
      }
    )
  )
  |> ignore
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

let changeConversation = (conversation: conversation, data, callback) => {
  open Js.Promise
  Fetch.fetchWithInit(
    apiBaseUrl ++
    ("/anfragen/immobilie/" ++
    (string_of_int(conversation.immobilie_id) ++
    ("/conversations/" ++
    string_of_int(conversation.id)))),
    Fetch.RequestInit.make(
      ~credentials=Include,
      ~method_=Post,
      ~body=Fetch.BodyInit.make(Js.Json.stringify(Js.Json.object_(data))),
      (),
    ),
  )
  |> then_(Fetch.Response.json)
  |> then_(json =>
    json
    |> Decode.single_conversation
    |> (
      conversation => {
        callback(conversation)
        resolve()
      }
    )
  )
  |> ignore
}

let rateConversation = (conversation: conversation, rating: option<rating>, callback) => {
  let data = Js.Dict.empty()
  Js.Dict.set(
    data,
    "rating",
    switch rating {
    | Some(Green) => Js.Json.string("green")
    | Some(Yellow) => Js.Json.string("yellow")
    | Some(Red) => Js.Json.string("red")
    | None => Js.Json.string("")
    },
  )
  changeConversation(conversation, data, callback)
}

let setReadStatusForConversation = (conversation: conversation, is_read: bool, callback) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, "is_read", Js.Json.boolean(is_read))
  changeConversation(conversation, data, callback)
}

let storeNotesForConversation = (conversation: conversation, notes: string, callback) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, "notes", Js.Json.string(notes))
  changeConversation(conversation, data, callback)
}

let trashConversation = (conversation: conversation, is_in_trash: bool, callback) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, is_in_trash ? "trash" : "untrash", Js.Json.string("x"))
  changeConversation(conversation, data, callback)
}

let ignoreConversation = (conversation: conversation, is_ignored: bool, callback) => {
  let data = Js.Dict.empty()
  Js.Dict.set(data, is_ignored ? "ignore" : "unignore", Js.Json.string("x"))
  changeConversation(conversation, data, callback)
}
