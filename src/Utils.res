let intEl = n => n |> string_of_int |> React.string

let floatEl = n => n |> Js.Float.toString |> React.string

let numberEl = n => n |> int_of_float |> string_of_int |> React.string

let textEl = React.string

let arrayEl = React.array

let array_filter = (func, arr) => arr |> Array.to_list |> List.filter(func) |> Array.of_list

let element_in_list = (element, selected_list) =>
  List.exists(other => other == element, selected_list)

let string_contains: (string, string) => bool = %raw(`
	function (haystack, needle) {
		return haystack.indexOf(needle) !== -1;
	}
`)

let max_length: (string, int, int) => string = %raw(`
		function (data, max_words, max_chars) {
			return data.substring(0, max_chars).split(" ").slice(0, max_words+1).join(" ");
		}
	`)
let setScrollTop: (Dom.element, int) => int = %raw(`
     function (domNode, i) {
       domNode.scrollTop = i;
       return 0;
     }
  `)

let getScrollTop: Dom.element => int = %raw(`
     function (domNode) {
       return domNode.scrollTop;
     }
  `)
