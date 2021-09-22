[%bs.raw {|require('./ConversationListItem.css')|}];

open Utils;

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationListItem");

let make =
    (
      ~onClick,
      ~onRating,
      ~onTrash,
      ~onReadStatus,
      ~onToggle,
      ~conversation: conversation,
      ~selected,
      ~active,
      _children,
    ) => {
  let localOnClick = (e): (ReactEvent.Mouse.t => unit) =>
    // don't reload messages if this conversation is currently selected
    if (!active) {
      onClick(e);
    } else {
      e => ();
    };
  {
    ...component,
    render: _self =>
      <div
        className={
          [
            "ConversationListItem",
            switch (conversation.rating) {
            | Some(Green) => "rating-green"
            | Some(Yellow) => "rating-yellow"
            | Some(Red) => "rating-red"
            | _ => "rating-unrated"
            },
            selected ? "selected" : "",
            active ? "active" : "",
            conversation.is_in_trash ? "is_in_trash" : "",
            !conversation.is_read ? "unread" : "",
          ]
          |> String.concat(" ")
        }>
        <div>
          <div>
            <div className="pull-left">
              <input
                className="toggle"
                type_="checkbox"
                checked=selected
                onChange={_ => onToggle(conversation)}
              />
              <span
                className="name pointer" onClick={localOnClick(conversation)}>
                {textEl(conversation.name)}
              </span>
            </div>
            <div className="pull-right">
              <ConversationRater conversation onRating />
              {/*if (! conversation.is_read) {
                      <i className="icon-asterisk" title="Ungelesen" />;
                 } else */
               if (conversation.is_replied_to) {
                 <i className="icon-reply" title="Beantwortet" />;
               } else {
                 ReasonReact.null;
               }}
              {if (conversation.has_attachments) {
                 <i
                   className="icon-paperclip"
                   title="Dateianhang vorhanden"
                 />;
               } else {
                 ReasonReact.null;
               }}
              {if (String.length(conversation.notes) > 0) {
                 <i className="icon-comment-alt" title="Notizen vorhanden" />;
               } else {
                 ReasonReact.null;
               }}
            </div>
          </div>
          <div className="clearfix" />
          <div className="info">
            <div className="date">
              <IsoDate
                date={Js.Date.fromString(conversation.date_last_message)}
              />
              <br />
              {textEl("um ")}
              <IsoTime
                date={Js.Date.fromString(conversation.date_last_message)}
              />
            </div>
          </div>
          <div>
            <div className="pointer" onClick={localOnClick(conversation)}>
              {if (conversation.latest_message.type_ == Outgoing) {
                 <em>
                   {textEl("Ihre Antwort: ")}
                   {textEl(
                      conversation.latest_message.content
                      ->max_length(20, 200),
                    )}
                 </em>;
               } else {
                 <span>
                   {textEl(
                      conversation.latest_message.content
                      ->max_length(20, 200),
                    )}
                 </span>;
               }}
            </div>
          </div>
        </div>
      </div>,
    /*
      <div className="pull-right">
        /*<button className="btn"> (textEl("Ignorieren")) </button>*/

          <button className="btn btn-primary"> (textEl("Antworten")) </button>
        </div>
      <div className="clearfix" />
     */
  };
};