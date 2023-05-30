/* %%raw(`import './FolderNavigationItem.css'`) */

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
    className={"flex items-center justify-between py-2 px-4 w-full " ++
    ((isActive ? "bg-blue-100 text-blue-500" : "") ++
    (" " ++ (unreadCount > 0 ? "unread" : "")))}
    onClick>
    <span className="space-x-2">
      <span className="inline-block w-4"> <i className={"main-icon " ++ icon} /> </span>
      <span> {label->React.string} </span>
    </span>
    <span className="pl-2"> {` (${count->Belt.Int.toString})`->React.string} </span>
  </button>
}
