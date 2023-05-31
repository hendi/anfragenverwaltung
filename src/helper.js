export function getAttribute(elementId, attributeName) {
  const element = document.querySelector(elementId);
  return element ? element.getAttribute(attributeName) : null;
}