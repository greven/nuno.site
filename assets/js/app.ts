import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from 'topbar';
import { morphdomOptions } from './dom';
import hooks from './hooks';

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  dom: morphdomOptions,
  hooks: hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: '#D95254' },
  barThickness: 3,
  shadowColor: 'rgba(0, 0, 0, .3)',
  shadowBlur: 4,
});

window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

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
  window.addEventListener('phx:live_reload:attached', (event) => {
    const { detail: reloader } = event as CustomEvent;

    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs();

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown: string | null = null;

    window.addEventListener('keydown', (e) => {
      keyDown = e.key;
    });
    window.addEventListener('keyup', (_e) => {
      keyDown = null;
    });
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
