@react.component
let make = (~date: Js.Date.t) => {
  <span> {date->DateFns.format("HH:mm", {"locale": DateFns.Locale.de})->React.string} </span>
}
