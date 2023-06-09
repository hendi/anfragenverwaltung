module File = {
  type t = {serverId: string}
}

module Instance = {
  type t

  @send external getFiles: t => array<File.t> = "getFiles"
}

@module("react-filepond") @react.component
external make: (
  ~ref: Instance.t => (),
  ~someValue: string=?,
  ~allowFileEncode: bool=?,
  ~maxFileSize: string=?,
  ~maxTotalFileSize: string=?,
  ~labelIdle: string=?,
  ~server: string=?,
  ~allowMultiple: bool=?,
  ~maxFiles: int=?,
  ~onprocessfilestart: File.t => unit=?,
  ~onprocessfileabort: File.t => unit=?,
  ~onprocessfileundo: File.t => unit=?,
  ~onprocessfile: File.t => unit=?,
  ~onremovefile: File.t => unit=?,
) => React.element = "FilePond"
