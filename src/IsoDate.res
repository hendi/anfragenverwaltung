@react.component
let make = (~date: Js.Date.t) => {
  <span> {date->DateFns.format("dd.MM.yyyy", {"locale": DateFns.Locale.de})->React.string} </span>
}
