open ConversationData

type item = {
  label: string,
  folder: Folder.t,
}

let items = [
  {label: "Neu & Unbearbeitet", folder: Folder.New},
  {label: "Unbeantwortet", folder: Folder.Unreplied},
  {label: "Interessant", folder: Folder.ByRating(Green)},
  {label: "Vielleicht", folder: Folder.ByRating(Yellow)},
  {label: "Uninteressant", folder: Folder.ByRating(Red)},
  {label: "Nicht bewertet", folder: Folder.ByRating(Unrated)},
  {label: "Zuvor beantwortet", folder: Folder.Replied},
  {label: "Alle Nachrichten", folder: Folder.All},
  {label: "Papierkorb", folder: Folder.Trash},
]

let getLabel = (f: Folder.t) => {
  let result = Belt.Array.getBy(items, item => item.folder == f)
  switch result {
    | Some(item) => item.label
    | None => ""
  }
}

@react.component
let make = (~activeFolder: Folder.t, ~foldersIsShowing: bool, ~onToggleFolders: ReactEvent.Mouse.t => unit) => {
  <div className="col-span-12 bg-slate-100 border lg:hidden">
    <div className="flex flex-row items-center justify-start text-xl p-2">
      <div onClick=onToggleFolders className="flex cursor-pointer hover:bg-blue-100 rounded items-center justify-center p-2 w-10 h-10 mr-2">
        <i className={foldersIsShowing ? "icon-caret-down" : "icon-caret-right"} />
      </div>
      {getLabel(activeFolder)->React.string}
    </div>
  </div>
}