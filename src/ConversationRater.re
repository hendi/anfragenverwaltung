[%bs.raw {|require('./ConversationRater.css')|}];

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationRater");

let make = (~conversation, ~onRating, _children) => {
  ...component,
  render: _self =>
    <div className="ConversationRater">
      <i
        onClick={onRating(conversation, Green)}
        className={
          [
            "icon-thumbs-up-alt",
            conversation.rating == Some(Green) ? "active" : "",
          ]
          |> String.concat(" ")
        }
        title="Als Favoriten markieren"
      />
      <i
        onClick={onRating(conversation, Yellow)}
        className={
          [
            "icon-unchecked",
            conversation.rating == Some(Yellow) ? "active" : "",
          ]
          |> String.concat(" ")
        }
        title="Als Vielleicht markieren"
      />
      <i
        onClick={onRating(conversation, Red)}
        className={
          [
            "icon-thumbs-down-alt",
            conversation.rating == Some(Red) ? "active" : "",
          ]
          |> String.concat(" ")
        }
        title="Als Uninteressant markieren"
      />
    </div>,
};