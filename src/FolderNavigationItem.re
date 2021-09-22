[%bs.raw {|require('./FolderNavigationItem.css')|}];

open Utils;

open ConversationData;

let component = ReasonReact.statelessComponent("FolderNavigationItem");

let make =
    (~active_folder, ~folder, ~icon, ~label, ~counter, ~onClick, _children) => {
  let unread_counter =
    counter(folder)
    |> Array.to_list
    |> List.filter(c => ! c.is_read)
    |> Array.of_list
    |> Array.length;
  {
    ...component,
    render: _self =>
      <div
        className=(
          "FolderNavigationItem"
          ++ " "
          ++ (folder == active_folder ? "active" : "")
          ++ " "
          ++ (unread_counter > 0 ? "unread" : "")
        )
        onClick=(onClick(folder))>
        <i className=("main-icon " ++ icon) />
        (textEl(label))
        <span className="pull-right">
          (counter(folder) |> Array.length |> intEl)
        </span>
      </div>,
  };
};
