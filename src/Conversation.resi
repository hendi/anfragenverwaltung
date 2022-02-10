open ConversationData

@react.component
let make: (
  ~conversation: conversation,
  ~onReplySend: (conversation, string, array<string>) => unit,
  ~onRating: (conversation, rating, ReactEvent.Mouse.t) => unit, 
  ~onTrash: (conversation, bool) => unit,
  ~onReadStatus: (conversation, bool) => unit,
  ~onIgnore: unit => unit,
  ~onSaveNotes: (conversation, string) => unit,
  ~onBack: unit => unit,
  ~messages: array<message>,
  ~loading: bool,
) => React.element
