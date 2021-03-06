%%raw(`import './ConversationRater.css'`)

open ConversationData


@react.component
let make = (~conversation, ~onRating) => {
    <div className="ConversationRater">
      <i
        onClick={onRating(conversation, Green)}
        className={list{
          "icon-thumbs-up-alt",
          conversation.rating == Some(Green) ? "active" : "",
        } |> String.concat(" ")}
        title="Als Favoriten markieren"
      />
      <i
        onClick={onRating(conversation, Yellow)}
        className={list{
          "icon-unchecked",
          conversation.rating == Some(Yellow) ? "active" : "",
        } |> String.concat(" ")}
        title="Als Vielleicht markieren"
      />
      <i
        onClick={onRating(conversation, Red)}
        className={list{
          "icon-thumbs-down-alt",
          conversation.rating == Some(Red) ? "active" : "",
        } |> String.concat(" ")}
        title="Als Uninteressant markieren"
      />
    </div>
}
