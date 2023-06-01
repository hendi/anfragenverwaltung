@react.component
let make: (
  ~activeFolder: ConversationData.Folder.t,
  ~foldersIsShowing: bool,
  ~onToggleFolders: ReactEvent.Mouse.t => unit
) => React.element