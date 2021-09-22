[%bs.raw {|require('./../node_modules/filepond/dist/filepond.min.css')|}];

[%bs.raw
  {|require('./../node_modules/filepond-polyfill/dist/filepond-polyfill.min.js')|}
];

[@bs.deriving abstract] [@bs.obj]
external makeProps:
  (
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
    unit
  ) =>
  _ =
  "";

[@bs.module "react-filepond"]
external filepond: ReasonReact.reactClass = "FilePond";

let make =
    (
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
      children,
    ) =>
  ReasonReact.wrapJsForReason(
    ~reactClass=filepond,
    ~props=
      makeProps(
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
    children,
  );
