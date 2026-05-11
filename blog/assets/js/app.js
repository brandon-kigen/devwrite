// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/blog";
import topbar from "../vendor/topbar";


// ═══════════════════════════════════════════════════════════════════════════
// Custom Hooks
// ═══════════════════════════════════════════════════════════════════════════

const CommentsManager = {
  mounted() {
    // Lazy loading logic
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.pushEvent("load_comments", {});
            observer.disconnect();
          }
        });
      },
      { threshold: 0.1 },
    );

    observer.observe(this.el);

    // Focus and Reset logic
    this.handleEvent("focus-comment-box", () => {
      const textarea = document.getElementById("comment-textarea");
      if (textarea) {
        textarea.scrollIntoView({ behavior: "smooth", block: "center" });
        textarea.focus();
      } else {
        // If not logged in, scroll to the comments section (where the login prompt is)
        const section = document.getElementById("comments-section");
        if (section) {
          section.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      }
    });

    this.handleEvent("reset-comment-form", () => {
      const textarea = document.getElementById("comment-textarea");
      if (textarea) {
        textarea.value = "";
      }
    });
  },
};

// ViewTracker: fires record_view only after user has been on the page for 60s.
// This prevents bot/reload inflation — the server no longer increments on connect.
const ViewTracker = {
  mounted() {
    this._timer = setTimeout(() => {
      this.pushEvent("record_view", {});
    }, 60_000); // 60 seconds
  },
  destroyed() {
    clearTimeout(this._timer);
  },
};

const TrixEditor = {
  mounted() {
    const hiddenInput = document.getElementById(this.el.dataset.inputId);

    // When trix content changes, update the hidden input so the form value is current
    this.el.addEventListener("trix-change", (e) => {
      hiddenInput.value = e.target.value;
    });

    // Set initial content if editing an existing post
    const editor = this.el.querySelector("trix-editor");
    if (
      hiddenInput.value &&
      editor &&
      !editor.editor.getDocument().toString().trim()
    ) {
      editor.editor.loadHTML(hiddenInput.value);
    }
  },
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ...colocatedHooks,
    CommentsManager,
    ViewTracker,
    TrixEditor,
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

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
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}

