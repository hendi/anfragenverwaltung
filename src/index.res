%%raw(`import './index.css'`)

/*
 [@bs.module "./registerServiceWorker"]
 external register_service_worker : unit => unit = "default";
 */
switch ReactDOM.querySelector("#root") {
| Some(root) =>
  let client = ReactQuery.Client.make()
  ReactDOM.render(
    <ReactQuery.Client.Provider client>
      <App.App immobilieId=177865 />
    </ReactQuery.Client.Provider>,
    root,
  )
| None => () // do nothing
}
/* register_service_worker(); */
