%raw(`require('./FolderNavigation.css')`)

open ConversationData


@react.component
let make = (~active_folder, ~onClick, ~counter) => {
    <div className="FolderNavigation">
      <FolderNavigationItem
        folder=New icon="icon-bolt" label="Neu & Unbearbeitet" counter active_folder onClick
      />
      <FolderNavigationItem
        folder=Unreplied icon="icon-exclamation" label="Unbeantwortet" counter active_folder onClick
      />
      <FolderNavigationItem
        folder=ByRating(Some(Green))
        icon="icon-thumbs-up-alt"
        label="Favoriten"
        counter
        active_folder
        onClick
      />
      <FolderNavigationItem
        folder=ByRating(Some(Yellow))
        icon="icon-unchecked"
        label="Vielleicht"
        counter
        active_folder
        onClick
      />
      <FolderNavigationItem
        folder=ByRating(Some(Red))
        icon="icon-thumbs-down-alt"
        label="Uninteressant"
        counter
        active_folder
        onClick
      />
      <FolderNavigationItem
        folder=ByRating(None)
        icon="icon-question"
        label="Nicht bewertet"
        counter
        active_folder
        onClick
      />
      <FolderNavigationItem
        folder=Replied icon="icon-reply" label="Zuvor beantwortet" counter active_folder onClick
      />
      <FolderNavigationItem
        folder=All icon="icon-envelope-alt" label="Alle Nachrichten" counter active_folder onClick
      />
      <FolderNavigationItem
        folder=Trash icon="icon-trash" label="Papierkorb" counter active_folder onClick
      />
    </div>
}
