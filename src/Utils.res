let intEl = n => React.string(string_of_int(n))

let floatEl = n => React.string(Js.Float.toString(n))

let numberEl = n => React.string(string_of_int(int_of_float(n)))

let textEl = React.string

let arrayEl = React.array

let array_filter = (func, arr) => Array.filter(func, arr)

let element_in_list = (element, selected_list) => selected_list->List.has(element, (a, b) => a == b)

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
