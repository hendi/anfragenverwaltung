@react.component
let make: (
  ~activeFolder: ConversationData.Folder.t,
  ~onFolderClick: ConversationData.Folder.t => unit,
  ~conversations: array<ConversationData.conversation>,
  ~showFoldersInMobile: bool,
  ~closeFoldersInMobile: unit => unit,
) => React.element
