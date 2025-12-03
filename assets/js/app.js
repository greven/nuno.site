import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from 'topbar';
import hooks from './hooks';

// Show progress bar
topbar.config({
  barColors: { 0: '#D95254' },
  barThickness: 2.5,
  shadowColor: 'rgba(0, 0, 0, .3)',
  shadowBlur: 4,
});

window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

// View Transition API
let transitionEls = [];
let transitionTypes = [];

window.addEventListener('phx:start-view-transition', (e) => {
  const opts = e.detail;
  if (opts.temp_name && e.target !== window) {
    e.target.style.viewTransitionName = opts.temp_name;
    transitionEls.push(e.target);
  }
  if (opts.type) {
    transitionTypes.push(opts.type);
  }
});

// LiveSocket setup
const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks,
  dom: {
    onDocumentPatch(start) {
      // View Transitions integration
      if (typeof document.startViewTransition === 'function') {
        const update = () => {
          transitionEls.forEach((el) => (el.style.viewTransitionName = ''));
          transitionEls = [];
          transitionTypes = [];

          return new Promise((resolve) =>
            // Small delay to ensure DOM is ready
            setTimeout(() => {
              start();
              resolve();
            }, 50)
          );
        };

        // Browsers that don't support callbackOptions (Firefox 144...)
        try {
          document.startViewTransition({
            update: update,
            types: transitionTypes.length ? transitionTypes : ['same-document'],
          });
        } catch (e) {
          document.startViewTransition(update);
        }
      } else {
        start();
      }
    },

    onBeforeElUpdated(from, to) {
      // Keep element attributes starting with data-js-* which we set on the client.
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

      // Dialog and Details elements
      if (['DIALOG', 'DETAILS'].indexOf(from.tagName) >= 0) {
        Array.from(from.attributes).forEach((attr) => {
          to.setAttribute(attr.name, attr.value);
        });
      }
    },

    onNodeAdded(node) {
      // Mimic autofocus for dynamically inserted elements
      if (node.nodeType === Node.ELEMENT_NODE && node.hasAttribute('autofocus')) {
        node.focus();

        const element = node;
        if (element.setSelectionRange && element.value) {
          const lastIndex = element.value.length;
          element.setSelectionRange(lastIndex, lastIndex);
        }
      }
    },
  },
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === 'development') {
  window.addEventListener('phx:live_reload:attached', ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs();

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown;
    window.addEventListener('keydown', (e) => (keyDown = e.key));
    window.addEventListener('keyup', (e) => (keyDown = null));
    window.addEventListener(
      'click',
      (e) => {
        if (keyDown === 'c') {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtCaller(e.target);
        } else if (keyDown === 'd') {
          e.preventDefault();
          e.stopImmediatePropagation();
          reloader.openEditorAtDef(e.target);
        }
      },
      true
    );

    window.liveReloader = reloader;
  });
}
