%raw(`require('./../node_modules/filepond/dist/filepond.min.css')`)

%raw(`require('./../node_modules/filepond-polyfill/dist/filepond-polyfill.min.js')`)

@deriving(abstract) @obj
external makeProps: (
  ~someValue: string=?,
  ~allowFileEncode: bool=?,
  ~maxFileSize: string=?,
  ~maxTotalFileSize: string=?,
  ~server: string=?,
  ~allowMultiple: bool=?,
  ~maxFiles: int=?,
  ~onprocessfilestart: string => unit=?,
  ~onprocessfileabort: string => unit=?,
  ~onprocessfileundo: string => unit=?,
  ~onprocessfile: string => unit=?,
  ~onremovefile: string => unit=?,
  unit,
) => _ = ""

@module("react-filepond")
//external filepond: React.reactClass = "FilePond"

@react.component
external make: React.element = "FilePond"

/*let make = (
  ~someValue=?,
  ~allowFileEncode=?,
  ~maxFileSize=?,
  ~maxTotalFileSize=?,
  ~server=?,
  ~allowMultiple=?,
  ~maxFiles=?,
  ~onprocessfilestart=?,
  ~onprocessfileabort=?,
  ~onprocessfileundo=?,
  ~onprocessfile=?,
  ~onremovefile=?,
) =>
  React.wrapJsForRescript(
    ~reactClass=filepond,
    ~props=makeProps(
      ~someValue?,
      ~allowFileEncode?,
      ~maxFileSize?,
      ~maxTotalFileSize?,
      ~server?,
      ~allowMultiple?,
      ~maxFiles?,
      ~onprocessfilestart?,
      ~onprocessfileabort?,
      ~onprocessfileundo?,
      ~onprocessfile?,
      ~onremovefile?,
      (),
    ),
  )
*/
