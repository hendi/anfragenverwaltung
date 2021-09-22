open Utils

@react.component
let make = (~date: Js.Date.t) => {
    <span>
        <IsoDate date /> {textEl(", ")} <IsoTime date />
    </span>
}
