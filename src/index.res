%raw(`require('./index.css')`)

/*
 [@bs.module "./registerServiceWorker"]
 external register_service_worker : unit => unit = "default";
 */
switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.render(<App.App immobilie_id=177865 />, root)
| None => () // do nothing
}
/* register_service_worker(); */
