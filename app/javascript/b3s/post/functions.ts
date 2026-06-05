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
  const body: HTMLBodyElement = elem.querySelector(".body");
  body.style.display = "none";

  const editor = document.createElement("div");
  editor.classList.add("edit");
  editor.innerHTML = '<span class="ticker">Loading...</span>';
  elem.append(editor);

  const cancelEdit = () => {
    editor.remove();
    body.style.display = "";
  };

  void fetch(post.editUrl(), {
    headers: {
      "X-Requested-With": "XMLHttpRequest"
    }
  })
    .then((response) => response.text())
    .then((body) => (editor.innerHTML = body))
    .then(() => {
      applyRichTextArea();

      const cancelButton: HTMLButtonElement =
        editor.querySelector("button.cancel");
      if (cancelButton) {
        cancelButton.addEventListener("click", (evt) => {
          evt.preventDefault();
          cancelEdit();
        });
      }

      const textarea: HTMLTextAreaElement = editor.querySelector("textarea");
      if (textarea) {
        textarea.addEventListener("keydown", (evt) => {
          if (evt.key === "Escape") {
            evt.preventDefault();
            cancelEdit();
          }
        });
        textarea.focus();
        textarea.setSelectionRange(
          textarea.value.length,
          textarea.value.length
        );
      }
    });
}

function postAttributes(elem: HTMLDivElement): Partial<PostAttributes> {
  if (!elem.dataset.postId) {
    return {};
  }
  return {
    id: parseInt(elem.dataset.postId, 10),
    user_id: parseInt(elem.dataset.userId, 10),
    exchange_id: parseInt(elem.dataset.exchangeId),
    exchange_type: elem.dataset.exchangeType
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
