import topbar from "../vendor/topbar";

// Show progress bar on live navigation and form submits
export function registerTopbar() {
  topbar.config({
    barColors: { 0: "#DD4C4F" },
    barThickness: 3,
    shadowColor: "rgba(0, 0, 0, .3)",
    shadowBlur: 4,
  });

  window.addEventListener("phx:page-loading-start", (_info) =>
    topbar.show(300)
  );
  window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
}

export function pageLoadingTransitions() {
  window.addEventListener("phx:page-loading-start", (info) => {
    if (info.detail.kind == "redirect") {
      const main = document.querySelector("main");
      main?.classList?.add("phx-page-loading");
    }
  });

  window.addEventListener("phx:page-loading-stop", (info) => {
    const main = document.querySelector("main");
    main?.classList?.remove("phx-page-loading");
  });
}
