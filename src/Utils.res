let elementInList = (element, selected_list) => selected_list->List.has(element, (a, b) => a == b)

let stringContains: (string, string) => bool = %raw(`
	function (haystack, needle) {
		return haystack.indexOf(needle) !== -1;
	}
`)

let maxLength: (string, int, int) => string = %raw(`
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
