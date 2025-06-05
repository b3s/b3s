export default function quote(elem: HTMLDivElement) {
  let html = "";
  let username: string;
  let url: string | null;

  const permalink: HTMLAnchorElement = elem.querySelector(
    ".post_info .permalink"
  );
  if (permalink && "href" in permalink) {
    url = permalink.href.replace(/^https?:\/\/([\w\d.:-]*)/, "");
  }

  if (
    window.getSelection != null &&
    window.getSelection().containsNode(elem, true)
  ) {
    html = window.getSelection().toString().trim().replace(/\n/g, "<br>");
  }

  if (html === "") {
    html = elem.querySelector(".body .content").innerHTML.trim();
  }

  if (elem.classList.contains("me_post")) {
    username = elem.querySelector(".body .poster").textContent;
  } else {
    username = elem.querySelector(".post_info .username a").textContent;
  }

  html = html.replace(/class="spoiler revealed"/g, 'class="spoiler"');
  html = html.replace(/<img alt="([\w+-]+)" class="emoji"([^>]*)>/g, ":$1:");

  document.dispatchEvent(
    new CustomEvent("quote", {
      detail: {
        username: username,
        permalink: url,
        html: html
      }
    })
  );
}
