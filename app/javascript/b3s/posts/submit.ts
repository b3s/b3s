import readyHandler from "../../lib/readyHandler";
import { csrfToken } from "../../lib/request";
import { loadNewPosts } from "./newPosts";

readyHandler.ready(() => {
  const textarea: HTMLTextAreaElement = document.querySelector("#compose-body");

  function completePost() {
    textarea.value = "";
    const preview = document.querySelector(".posts #previewPost");
    if (preview) {
      preview.remove();
    }
    void loadNewPosts();
  }

  // Submit post via AJAX
  async function submitPost(form: HTMLFormElement) {
    document.dispatchEvent(
      new CustomEvent("posting-status", {
        detail: "Posting, please wait&hellip;"
      })
    );

    const body = textarea.value;
    const formatElement: HTMLInputElement = form.querySelector(".format");
    const format = formatElement.value;

    await fetch(form.action, {
      method: "post",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "X-CSRF-Token": csrfToken(),
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify({
        post: { body: body, format: format },
        format: "json"
      })
    })
      .then((response) => {
        if (response.ok) {
          return response.text();
        }
        return response.text().then((t) => {
          throw new Error(t);
        });
      })
      .then(() => completePost())
      .catch((error) => alert(error));

    document.dispatchEvent(new Event("posting-complete"));
  }

  // Form event handler
  document
    .querySelectorAll("#replyText form")
    .forEach((form: HTMLFormElement) => {
      if (form.classList.contains("livePost")) {
        form.addEventListener("submit", (evt) => {
          evt.preventDefault();
          if (textarea.value.trim() !== "") {
            void submitPost(form);
          }
        });
      }
    });
});
