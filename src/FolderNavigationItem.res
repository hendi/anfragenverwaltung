%%raw(`import './FolderNavigationItem.css'`)

open Utils

open ConversationData

@react.component
let make = (
  ~active_folder: ConversationData.folder,
  ~folder: ConversationData.folder,
  ~icon: string,
  ~label: string,
  ~counter: ConversationData.folder => array<ConversationData.conversation>,
  ~onClick: (ConversationData.folder, ReactEvent.Mouse.t) => unit,
) => {
  let unread_counter = counter(folder)->Js.Array2.filter(c => c.is_read)->Belt.Array.length

  let all_counter = counter(folder)->Js.Array2.length

  <div
    className={"FolderNavigationItem" ++
    (" " ++
    ((folder == active_folder ? "active" : "") ++ (" " ++ (unread_counter > 0 ? "unread" : ""))))}
    onClick={onClick(folder)}>
    <i className={"main-icon " ++ icon} />
    {textEl(label)}
    <span className="pull-right"> {` (${all_counter->Belt.Int.toString})`->React.string} </span>
  </div>
}
