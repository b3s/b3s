import readyHandler from "../../lib/readyHandler";
import { csrfToken } from "../../lib/request";

function updatePreview(html: string) {
  const posts = document.querySelector(".posts");
  let container: HTMLDivElement = document.querySelector(".posts #container");

  // Inject the #ajaxPosts container so new posts
  // will be loaded above the preview
  if (!posts.querySelector("#ajaxPosts")) {
    const ajaxPosts = document.createElement("div");
    ajaxPosts.id = "ajaxPosts";
    posts.appendChild(ajaxPosts);
  }

  if (!container) {
    container = document.createElement("div");
    container.id = "container";
    posts.appendChild(container);
  }

  container.innerHTML = html;
  container.classList.remove("loading");

  document.dispatchEvent(
    new CustomEvent("postsloaded", {
      detail: [container.querySelector(".post")]
    })
  );
}

readyHandler.ready(() => {
  async function previewPost() {
    const textarea: HTMLTextAreaElement =
      document.querySelector("#compose-body");
    const form = textarea.closest("form");

    const postBody = textarea.value;
    const formatElement: HTMLInputElement = form.querySelector(".format");
    const format = formatElement.value;
    const previewUrl = form.dataset.previewUrl;

    document.dispatchEvent(
      new CustomEvent("posting-status", {
        detail: "Loading preview&hellip;"
      })
    );

    const previewPost = document.querySelector(".posts #previewPost");
    if (previewPost) {
      previewPost.classList.add("loading");
    }

    await fetch(previewUrl, {
      method: "post",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "X-CSRF-Token": csrfToken(),
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify({
        post: { body: postBody, format: format }
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
      .then((body) => updatePreview(body))
      .catch((error) => alert(error));

    document.dispatchEvent(new Event("posting-complete"));
  }

  const previewButton = document.querySelector("#replyText .preview");
  if (previewButton) {
    previewButton.addEventListener("click", (evt) => {
      evt.preventDefault();
      void previewPost();
    });
  }
});
