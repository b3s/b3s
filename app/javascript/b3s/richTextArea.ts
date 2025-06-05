import B3S from "../b3s";

import HtmlDecorator from "./richTextArea/HtmlDecorator";
import MarkdownDecorator from "./richTextArea/MarkdownDecorator";
import { getSelection, replaceSelection } from "./richTextArea/selection";
import { bindUploads, uploadImage } from "./richTextArea/upload";

import { putJson } from "../lib/request";

function undoEmbeds(html: string) {
  const elem = document.createElement("div");
  elem.innerHTML = html;
  elem.querySelectorAll("div.embed[data-oembed-url]").forEach(function (
    embed: HTMLDivElement
  ) {
    embed.parentNode.insertBefore(
      document.createTextNode(embed.dataset.oembedUrl),
      embed
    );
    embed.parentNode.removeChild(embed);
  });
  return elem.innerHTML;
}

export default function richTextArea(textarea: RichText.Element) {
  if (textarea.richtext) {
    return;
  }
  textarea.richtext = true;

  let decorator: RichText.Decorator = new MarkdownDecorator();
  let formats = ["markdown"];
  let format = "markdown";

  const formatButton = document.createElement("li");
  formatButton.className = "formatting";
  formatButton.innerHTML = "<a>Markdown</a>";

  const icons = B3S.Configuration.emoticons;

  const toolbar = document.createElement("ul");
  toolbar.className = "richTextToolbar clearfix";
  toolbar.appendChild(formatButton);
  textarea.parentNode.insertBefore(toolbar, textarea);

  const emojiBar = document.createElement("ul");
  emojiBar.className = "emojiBar clearfix";
  emojiBar.style.display = "none";
  textarea.parentNode.insertBefore(emojiBar, textarea);

  if (textarea.dataset.formats) {
    formats = textarea.dataset.formats.split(" ");
  }

  if (textarea.dataset.formatBinding) {
    const formatElem: HTMLInputElement = textarea
      .closest("form")
      .querySelector(textarea.dataset.formatBinding);
    if (formatElem && "value" in formatElem) {
      format = formatElem.value;
    }
  }
  if (textarea.dataset.rememberFormat) {
    if (B3S.Configuration.preferredFormat) {
      format = B3S.Configuration.preferredFormat;
    }
  }
  format = format || formats[0];

  function setFormat(newFormat: string, skipUpdate?: boolean) {
    let label: string;
    format = newFormat;

    if (format === "markdown") {
      label = "Markdown";
      decorator = new MarkdownDecorator();
    } else if (format === "html") {
      label = "HTML";
      decorator = new HtmlDecorator();
    }

    formatButton.querySelector("a").innerHTML = label;

    if (textarea.dataset.formatBinding) {
      const formatElem: HTMLInputElement = textarea
        .closest("form")
        .querySelector(textarea.dataset.formatBinding);
      formatElem.value = format;
    }

    if (textarea.dataset.rememberFormat && !skipUpdate) {
      if (B3S.Configuration.currentUserId) {
        void putJson(`/users/${B3S.Configuration.currentUserId}.json`, {
          user: { preferred_format: newFormat }
        });
      }
    }
  }

  function nextFormat() {
    return setFormat(formats[(formats.indexOf(format) + 1) % formats.length]);
  }

  setFormat(format, true);

  formatButton.querySelector("a").addEventListener("click", (evt) => {
    evt.preventDefault();
    nextFormat();
  });

  function performAction(callback: RichText.Action) {
    const result = callback(getSelection(textarea));
    if (result) {
      const [prefix, replacement, postfix] = result;
      replaceSelection(textarea, prefix, replacement, postfix);
    }
  }

  function addButton(
    name: string,
    className: string,
    callback: RichText.Action
  ) {
    const li = document.createElement("li");
    li.className = "button";

    const link = document.createElement("a");
    link.title = name;
    link.className = className;
    link.innerHTML = `<i class="fa-solid fa-${className}"></i>`;
    link.addEventListener("click", (evt) => {
      evt.preventDefault();
      performAction(callback);
    });

    li.appendChild(link);
    toolbar.insertBefore(li, formatButton);
  }

  function addHotkey(hotkey: string, callback: RichText.Action) {
    textarea.addEventListener("keydown", (evt: KeyboardEvent) => {
      let key;
      if (evt.which >= 65 && evt.which <= 90) {
        key = String.fromCharCode(evt.keyCode).toLowerCase();
      } else if (evt.keyCode === 13) {
        key = "enter";
      }

      if ((evt.metaKey || evt.ctrlKey) && key === hotkey) {
        evt.preventDefault();
        performAction(callback);
      }
    });
  }

  const bold = (s: string) => decorator.bold(s);
  const italic = (s: string) => decorator.emphasis(s);
  const blockquote = (s: string) => decorator.blockquote(s);
  const spoiler = (s: string) => decorator.spoiler(s);

  const link = (s: string) => {
    const name = s.length > 0 ? s : "Link text";
    let url = prompt("Enter link URL", "");
    url = url.length > 0 ? url : "http://example.com/";
    url = url.replace(/^(?!(f|ht)tps?:\/\/)/, "http://");
    return decorator.link(url, name);
  };

  const imageTag = (s: string) => {
    const url = s.length > 0 ? s : prompt("Enter image URL", "");
    return url ? decorator.image(url) : null;
  };

  const uploadImageAction = () => uploadImage(textarea);

  const code = (selection: string) => {
    const lang = prompt(
      "Enter language (leave blank for no syntax highlighting)",
      ""
    );
    return decorator.code(selection, lang);
  };

  const showEmojiBar = (selection: string): RichText.Replacement => {
    if (emojiBar.style.display == "none") {
      emojiBar.style.display = "block";
    } else {
      emojiBar.style.display = "none";
    }
    return ["", selection, ""];
  };

  const submit = () => {
    textarea.closest("form").submit();
  };

  addButton("Bold", "bold", bold);
  addButton("Italics", "italic", italic);
  addButton("Link", "link", link);
  addButton("Image", "image", imageTag);
  addButton("Upload Image", "upload", uploadImageAction);
  addButton("Block Quote", "quote-left", blockquote);
  addButton("Code", "code", code);
  addButton("Spoiler", "warning", spoiler);
  addButton("Emoticons", "face-smile", showEmojiBar);

  addHotkey("b", bold);
  addHotkey("i", italic);
  addHotkey("k", link);
  addHotkey("enter", submit);

  document.addEventListener("quote", (event: QuoteEvent) => {
    const [prefix, replacement, postfix] = decorator.quote(
      undoEmbeds(event.detail.html),
      event.detail.username,
      event.detail.permalink
    );
    replaceSelection(textarea, prefix, replacement, postfix);
    textarea.scrollTop = textarea.scrollHeight;
  });

  function addEmojiButton(name: string, image: string) {
    const li = document.createElement("li");
    li.className = "button";

    const link = document.createElement("a");
    link.title = name;
    link.addEventListener("click", (evt) => {
      evt.preventDefault();
      replaceSelection(textarea, "", ":" + name + ": ", "");
    });

    const img = document.createElement("img");
    img.alt = name;
    img.className = "emoji";
    img.src = image;
    img.width = 16;
    img.height = 16;

    li.appendChild(link);
    link.appendChild(img);
    emojiBar.appendChild(li);
  }

  for (let j = 0; j < icons.length; j++) {
    addEmojiButton(icons[j].name, icons[j].image);
  }

  if (B3S.Configuration.uploads) {
    bindUploads(textarea);
  }
}

export function applyRichTextArea() {
  document
    .querySelectorAll("textarea.rich")
    .forEach((textarea: RichText.Element) => {
      richTextArea(textarea);
    });
}
