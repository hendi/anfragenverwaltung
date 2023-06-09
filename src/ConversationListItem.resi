@react.component
let make: (
  ~onClick: ReactEvent.Mouse.t => unit=?,
  ~onRating: (ConversationData.conversation, ConversationData.rating, ReactEvent.Mouse.t) => unit,
  ~onToggleSelect: ConversationData.conversation => unit,
  ~conversation: ConversationData.conversation,
  ~selected: bool,
  ~active: bool,
) => React.element
