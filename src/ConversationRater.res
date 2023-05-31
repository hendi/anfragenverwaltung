open ConversationData

module RateButton = {
  type icon = [#"icon-thumbs-up-alt" | #"icon-unchecked" | #"icon-thumbs-down-alt"]
  @react.component
  let make = (~active=false, ~icon: icon, ~title: string, ~onClick: ReactEvent.Mouse.t => unit) => {
    let fontWeight = active ? "font-bold" : "font-normal"

    <button
      onClick
      title
      className={`w-6 h-6 inline-flex justify-center items-center`}>
      <i className={`${fontWeight} hover:font-bold ${(icon :> string)}`} />
    </button>
  }
}

@react.component
let make = (~conversation, ~onRating) => {
  <div>
    <RateButton
      icon=#"icon-thumbs-up-alt"
      onClick={evt => onRating(conversation, conversation.rating === Green ? Unrated : Green, evt)}
      title="Als Favoriten markieren"
      active={conversation.rating == Green}
    />
    <RateButton
      icon=#"icon-unchecked"
      onClick={evt => onRating(conversation, conversation.rating === Yellow ? Unrated : Yellow, evt)}
      title="Als Vielleicht markieren"
      active={conversation.rating == Yellow}
    />
    <RateButton
      onClick={evt => onRating(conversation, conversation.rating === Red ? Unrated : Red, evt)}
      icon=#"icon-thumbs-down-alt"
      title="Als Uninteressant markieren"
      active={conversation.rating == Red}
    />
  </div>
}
