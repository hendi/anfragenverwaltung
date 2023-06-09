@react.component
let make: (
  ~activeFolder: ConversationData.Folder.t,
  ~foldersIsShowing: bool,
  ~onToggleFolders: ReactEvent.Mouse.t => unit,
  ~isFolder: bool,
  ~goBack: ReactEvent.Mouse.t => unit,
  ~label: string=?,
) => React.element