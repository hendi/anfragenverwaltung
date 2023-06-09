export function getAttribute(elementId, attributeName) {
  const element = document.querySelector(elementId);
  const attribute = element.getAttribute(attributeName);
  return attribute ? attribute : null;
}