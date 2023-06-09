@react.component
let make = (~date: Js.Date.t) => {
    <span>
        <IsoDate date /> {", "->React.string} <IsoTime date />
    </span>
}
