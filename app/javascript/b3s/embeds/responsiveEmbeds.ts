import readyHandler from "../../lib/readyHandler";

const selectors = [
  'iframe[src*="bandcamp.com"]',
  'iframe[src*="player.vimeo.com"]',
  'iframe[src*="youtube.com"]',
  'iframe[src*="youtube-nocookie.com"]',
  'iframe[src*="spotify.com"]',
  'iframe[src*="kickstarter.com"][src*="video.html"]'
];

function wrapEmbed(embed: HTMLElement): HTMLElement {
  const parent = embed.parentNode as HTMLElement;

  // Recycle the existing container if the embed is already responsive.
  if (
    parent &&
    parent.tagName === "DIV" &&
    parent.childNodes.length === 1 &&
    parent.style.position === "relative"
  ) {
    return parent;
  }

  const wrapper = document.createElement("div");
  if (parent.tagName === "P") {
    parent.parentNode.replaceChild(wrapper, parent);
  } else {
    parent.replaceChild(wrapper, embed);
  }
  wrapper.appendChild(embed);
  return wrapper;
}

function applyEmbed(embed: HTMLElement) {
  const parent = embed.parentNode as HTMLElement;

  if (parent && parent.classList.contains("responsive-embed")) {
    return;
  }

  const width = embed.offsetWidth;
  const height = embed.offsetHeight;
  const ratio = height / width;
  const wrapper = wrapEmbed(embed);

  wrapper.classList.add("responsive-embed");
  wrapper.style.position = "relative";
  wrapper.style.width = "100%";
  wrapper.style.paddingTop = "0";
  wrapper.style.paddingBottom = `${ratio * 100}%`;

  embed.style.position = "absolute";
  embed.style.width = "100%";
  embed.style.height = "100%";
  embed.style.top = "0";
  embed.style.left = "0";
}

export default function responsiveEmbeds() {
  readyHandler.ready(() => {
    document.querySelectorAll(selectors.join(",")).forEach(applyEmbed);
  });
}
