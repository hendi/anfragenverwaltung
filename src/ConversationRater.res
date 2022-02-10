/* %%raw(`import './ConversationRater.css'`) */

open ConversationData

module RateButton = {
  type icon = [#"icon-thumbs-up-alt" | #"icon-unchecked" | #"icon-thumbs-down-alt"]
  @react.component
  let make = (~active=false, ~icon: icon, ~title: string, ~onClick: ReactEvent.Mouse.t => unit) => {
    let borderColor = active ? "border-black" : "border-transparent" 

    <button
      onClick
      title
      className=`w-6 h-6 bg-gray-200 ${borderColor} border-2 hover:border-black rounded-md inline-flex justify-center items-center`>
      <i className={(icon :> string)} />
    </button>
  }
}

@react.component
let make = (~conversation, ~onRating) => {
  <div className="space-x-1">
    <RateButton
      icon=#"icon-thumbs-up-alt"
      onClick={onRating(conversation, Green)}
      title="Als Favoriten markieren"
      active={conversation.rating == Green}
    />
    <RateButton
      icon=#"icon-unchecked"
      onClick={onRating(conversation, Yellow)}
      title="Als Vielleicht markieren"
      active={conversation.rating == Yellow}
    />
    <RateButton
      onClick={onRating(conversation, Red)}
      icon=#"icon-thumbs-down-alt"
      title="Als Uninteressant markieren"
      active={conversation.rating == Red}
    />
  </div>
}
