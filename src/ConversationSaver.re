[%bs.raw {|require('./ConversationSaver.css')|}];

open ConversationData;

let component = ReasonReact.statelessComponent("ConversationSaver");

let make = (~conversation: conversation, _children) => {
  ...component,
  render: _self =>
    <div className="ConversationSaver">
      <a href=("https://www.ohne-makler.net/anfragen/immobilie/" ++ string_of_int(conversation.immobilie_id) ++ "/backup/?c=" ++ string_of_int(conversation.id)) target="_blank">
        <i
          className="icon-save"
          title="Unterhaltung als PDF herunterladen"
        />
      </a>
    </div>,
};
