/* %%raw(`import './FolderNavigationItem.css'`) */

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

  <button
    className={"flex justify-between py-2 px-4 items-center w-full " ++
    ((isActive ? "bg-blue-400 text-white" : "") ++
    (" " ++ (unreadCount > 0 ? "unread" : "")))}
    onClick>
    <span className="space-x-2">
      <span className="inline-block w-4"> <i className={"main-icon " ++ icon} /> </span>
      <span> {textEl(label)} </span>
    </span>
    <span className="pl-2"> {` (${count->Belt.Int.toString})`->React.string} </span>
  </button>
}
