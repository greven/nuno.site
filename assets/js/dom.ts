export const morphdomOptions = {
  onBeforeElUpdated(from: HTMLElement, to: HTMLElement) {
    // Keep element attributes starting with data-js-
    // which we set on the client.
    for (const attr of from.attributes) {
      if (attr.name.startsWith('data-js-')) {
        to.setAttribute(attr.name, attr.value);
      }

      if (attr.name === 'data-keep-attribute') {
        if (from.hasAttribute(attr.value)) {
          const attrValue = from.getAttribute(attr.value);
          if (attrValue) {
            to.setAttribute(attr.value, attrValue);
          }
        } else {
          to.removeAttribute(attr.value);
        }
      }
    }
  },

  onNodeAdded(node: Node) {
    // Mimic autofocus for dynamically inserted elements
    if (node.nodeType === Node.ELEMENT_NODE && (node as HTMLElement).hasAttribute('autofocus')) {
      (node as HTMLElement).focus();

      const element = node as HTMLInputElement;
      if (element.setSelectionRange && element.value) {
        const lastIndex = element.value.length;
        element.setSelectionRange(lastIndex, lastIndex);
      }
    }
  },
};
