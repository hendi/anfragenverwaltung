%%raw(`import './FolderNavigationItem.css'`)

open Utils

@react.component
let make = (
  ~isActive: bool=false,
  ~icon: string,
  ~label: string,
  ~count: int,
  ~unreadCount: int,
  ~onClick: ReactEvent.Mouse.t => unit,
) => {
  /*
  let unread_counter = counter(folder)->Js.Array2.filter(c => c.is_read)->Belt.Array.length
  let all_counter = counter(folder)->Js.Array2.length
 */

  <div
    className={"FolderNavigationItem" ++
    (" " ++
    ((isActive ? "active" : "") ++ (" " ++ (unreadCount > 0 ? "unread" : ""))))}
    onClick>
    <i className={"main-icon " ++ icon} />
    {textEl(label)}
    <span className="pull-right"> {` (${count->Belt.Int.toString})`->React.string} </span>
  </div>
}
