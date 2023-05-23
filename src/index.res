%%raw(`import './index.css'`)
%%raw(`import 'filepond/dist/filepond.min.css'`)
%%raw(`import 'filepond-polyfill/dist/filepond-polyfill.min.js'`)

/*
 [@bs.module "./registerServiceWorker"]
 external register_service_worker : unit => unit = "default";
 */
switch ReactDOM.querySelector("#root") {
| Some(container) =>
  let client = ReactQuery.Client.make()
  let root = ReactDOM.Client.createRoot(container)

  let element =
    <ReactQuery.Client.Provider client>
      <App immobilieId=177865 />
    </ReactQuery.Client.Provider>

  root->ReactDOM.Client.Root.render(element)
| None => () // do nothing
}
/* register_service_worker(); */
