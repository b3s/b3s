import readyHandler from "../lib/readyHandler";

readyHandler.ready(() => {
  document.querySelectorAll("#search form").forEach((form: HTMLFormElement) => {
    const searchMode: HTMLSelectElement = form.querySelector("#search_mode");
    searchMode.addEventListener("change", () => {
      form.action = searchMode.value;
    });

    form.addEventListener("submit", (evt) => {
      evt.preventDefault();
      const queryInput: HTMLInputElement = form.querySelector(".query");
      const query = encodeURIComponent(queryInput.value);
      let action = form.action as string;
      if (!action.match(/^https?:\/\//)) {
        const baseDomain = document.location
          .toString()
          .match(/^(https?:\/\/[\w\d\-.]+)/)[1];
        action = baseDomain + action;
      }
      document.location = action + "?q=" + query;
    });
  });
});
