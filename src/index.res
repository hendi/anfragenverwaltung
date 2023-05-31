%%raw(`import './index.css'`)
%%raw(`import 'filepond/dist/filepond.min.css'`)
%%raw(`import 'filepond-polyfill/dist/filepond-polyfill.min.js'`)
@bs.module("./helper.js") external getAttribute: (string, string) => option<int> = "getAttribute"


/*
 [@bs.module "./registerServiceWorker"]
 external register_service_worker : unit => unit = "default";
 */
switch ReactDOM.querySelector("#root") {
| Some(container) =>
  let client = ReactQuery.Client.make()
  let root = ReactDOM.Client.createRoot(container)

  /*
    The immobilie.id is passed directly to the root div
    <div id="root" immobilie-id="{{ immobilie.id }}"></div>
  */

  let immobilieId = switch (getAttribute("#root", "immobilie-id")) {
  | Some(id) => id
  | None => 177865
  }

  let element =
    <ReactQuery.Client.Provider client>
      <App immobilieId=immobilieId />
    </ReactQuery.Client.Provider>

  root->ReactDOM.Client.Root.render(element)
| None => () // do nothing

}
/* register_service_worker(); */
