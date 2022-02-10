/*%%raw(`import './FolderNavigation.css'`)*/

open ConversationData

type item = {
  icon: string,
  label: string,
  folder: Folder.t,
}

let items = [
  {label: "Neu & Unbearbeitet", icon: "icon-bolt", folder: Folder.New},
  {label: "Unbeantwortet", icon: "icon-exclamation", folder: Folder.Unreplied},
  {label: "Interessant", icon: "icon-thumbs-up-alt", folder: Folder.ByRating(Green)},
  {label: "Vielleicht", icon: "icon-unchecked", folder: Folder.ByRating(Yellow)},
  {label: "Uninteressant", icon: "icon-thumbs-down-alt", folder: Folder.ByRating(Red)},
  {label: "Nicht bewertet", icon: "icon-question", folder: Folder.ByRating(Unrated)},
  {label: "Zuvor beantwortet", icon: "icon-reply", folder: Folder.Replied},
  {label: "Alle Nachrichten", icon: "icon-envelope-alt", folder: Folder.All},
  {label: "Papierkorb", icon: "icon-trash", folder: Folder.Trash},
]

let filterByFolder = (conversations, folder) => {
  switch folder {
  | Folder.All => conversations
  | New =>
    conversations->Js.Array2.filter(c => {
      (!c.is_in_trash && (c.rating == Unrated && (!c.is_replied_to && !c.is_ignored))) ||
        (!c.is_in_trash && !c.is_read)
    })
  | ByRating(rating) =>
    conversations->Js.Array2.filter(c => {
      !c.is_in_trash && c.rating == rating
    })
  | Unreplied =>
    conversations->Js.Array2.filter(c => {
      !c.is_in_trash && (!c.is_replied_to && !c.is_ignored)
    })
  | Replied =>
    conversations->Js.Array2.filter(c => {
      !c.is_in_trash && c.has_been_replied_to
    })
  | Trash =>
    conversations->Js.Array2.filter(c => {
      c.is_in_trash
    })
  }
}

@react.component
let make = (
  ~activeFolder: Folder.t,
  ~onFolderClick: Folder.t => unit,
  ~conversations: array<ConversationData.conversation>,
) => {
  <div>
    {Belt.Array.map(items, ({label, icon, folder}) => {
      let onClick = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        onFolderClick(folder)
      }

      let filtered = filterByFolder(conversations, folder)

      let unreadCount =
        filtered
        ->Js.Array2.filter(conv => {
          !conv.is_read
        })
        ->Belt.Array.length

      <FolderNavigationItem
        key=label
        isActive={activeFolder == folder}
        unreadCount
        count={Belt.Array.length(filtered)}
        icon
        label
        onClick
      />
    })->React.array}
  </div>
}
