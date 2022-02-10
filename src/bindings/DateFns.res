module Locale = {
  type t

  @module("date-fns/locale") external de: t = "de"
  @module("date-fns/locale") external en: t = "en"
}
@module("date-fns/format")
external format: (Js.Date.t, string, {"locale": Locale.t}) => string = "default"
