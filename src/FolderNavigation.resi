@react.component
let make: (
  ~activeFolder: ConversationData.Folder.t,
  ~onFolderClick: ConversationData.Folder.t => unit,
  ~conversations: array<ConversationData.conversation>,
) => React.element
