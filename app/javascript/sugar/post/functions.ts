import Post from "../../models/Post";
import { currentUser } from "../../models/User";
import quote from "./quote";
import { applyRichTextArea } from "../richTextArea";

function createLink(label: string, className: string, callback: () => void) {
  const link = document.createElement("a");
  link.href = "#";
  link.innerHTML = label;
  link.classList.add(className);
  link.addEventListener("click", (evt) => {
    evt.preventDefault();
    callback();
  });
  return link;
}

function editPost(post: Post, elem: HTMLDivElement) {
  const body = elem.querySelector(".body");
  if ("style" in body) {
    body.style.display = "none";
  }

  const editor = document.createElement("div");
  editor.classList.add("edit");
  editor.innerHTML = '<span class="ticker">Loading...</span>';
  elem.append(editor);

  void fetch(post.editUrl(), {
    headers: {
      "X-Requested-With": "XMLHttpRequest"
    }
  })
    .then((response) => response.text())
    .then((body) => (editor.innerHTML = body))
    .then(() => applyRichTextArea());
}

function postAttributes(elem: HTMLDivElement): PostAttributes {
  if (!elem.dataset.post_id) {
    return {};
  }
  return {
    id: elem.dataset.post_id,
    user_id: elem.dataset.user_id,
    exchange_id: elem.dataset.exchange_id,
    exchange_type: elem.dataset.exchange_type
  };
}

export default function functions(elem: HTMLDivElement) {
  const post = new Post(postAttributes(elem));

  const container = elem.querySelector(".post_functions");

  if (container && currentUser()) {
    if (post.editableBy(currentUser())) {
      container.append(
        createLink("Edit", "edit_post", () => editPost(post, elem)),
        " | "
      );
    }

    container.append(createLink("Quote", "quote_post", () => quote(elem)));
  }
}
