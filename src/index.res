%%raw(`import './index.css'`)
%%raw(`import 'filepond/dist/filepond.min.css'`)
%%raw(`import 'filepond-polyfill/dist/filepond-polyfill.min.js'`)
@bs.module("./helper.js") external getAttribute: (string, string) => Js.Nullable.t<string> = "getAttribute"


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
  let fallbackId = 177865

  let immobilieId = switch (getAttribute("#root", "immobilie-id")->Js.Nullable.toOption) {
    | Some(id) => switch (Belt.Int.fromString(id)) {
          | Some(intId) => intId
          | None => fallbackId
    }
    | None => fallbackId
  }

  Js.log(immobilieId)

  let element =
    <ReactQuery.Client.Provider client>
      <App immobilieId=immobilieId />
    </ReactQuery.Client.Provider>

  root->ReactDOM.Client.Root.render(element)
| None => () // do nothing

}
/* register_service_worker(); */
