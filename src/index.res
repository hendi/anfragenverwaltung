%%raw(`import * as Sentry from '@sentry/react'`)
%%raw(`
  Sentry.init({
    dsn: "https://4c6b36c096b34858a9cb70eb178fdc47@o4809.ingest.sentry.io/4505357460373504",
  });
`)

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
  let fallbackId = 232806

  let immobilieId = switch (getAttribute("#root", "immobilie-id")->Js.Nullable.toOption) {
    | Some(id) => switch (Belt.Int.fromString(id)) {
          | Some(intId) => intId
          | None => fallbackId
    }
    | None => fallbackId
  }

  let element =
    <ReactQuery.Client.Provider client>
      <App immobilieId=immobilieId />
    </ReactQuery.Client.Provider>

  root->ReactDOM.Client.Root.render(element)
| None => () // do nothing

}
/* register_service_worker(); */
