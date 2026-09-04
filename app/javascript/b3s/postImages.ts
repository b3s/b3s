import readyHandler from "../lib/readyHandler";

function linkImages() {
  document
    .querySelectorAll<HTMLImageElement>(".post .body img")
    .forEach((img) => {
      if (img.closest("a")) return;

      const link = document.createElement("a");
      link.href = img.dataset.fullSrc ?? img.src;

      const target: Element = img.closest("picture") ?? img;
      target.replaceWith(link);
      link.append(target);
    });
}

readyHandler.ready(linkImages);
document.addEventListener("postsloaded", linkImages);
