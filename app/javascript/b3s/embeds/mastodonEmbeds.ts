type EventData = {
  id: string;
  height: number;
  type: string;
};

type ResizeEvent = Event & {
  data?: EventData;
};

function embedUrl(value: string | undefined): string | null {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    return null;
  }

  if (
    url.protocol !== "https:" ||
    url.username ||
    url.password ||
    !url.pathname.endsWith("/embed")
  ) {
    return null;
  }

  return url.toString();
}

function replaceBlockquotes() {
  document
    .querySelectorAll(".post .body blockquote.mastodon-embed[data-embed-url]")
    .forEach((blockquote: HTMLQuoteElement) => {
      const src = embedUrl(blockquote.dataset.embedUrl);

      if (!src || blockquote.querySelector("iframe")) {
        return;
      }

      const iframe = document.createElement("iframe");
      iframe.className = "mastodon-embed";
      iframe.sandbox.add("allow-scripts", "allow-same-origin", "allow-popups");
      iframe.allow = "fullscreen";
      iframe.allowFullscreen = true;
      iframe.width = `${blockquote.clientWidth || 400}`;
      iframe.style.border = "0";
      iframe.style.display = "block";
      iframe.style.maxWidth = "100%";
      iframe.src = src;

      blockquote.replaceWith(iframe);
    });
}

export default function mastodonEmbeds() {
  replaceBlockquotes();

  const iframes = new Map<string, HTMLIFrameElement>();

  const iframeId = () => {
    const idBuffer = new Uint32Array(1);
    let id = 0;
    while (id === 0 || iframes.has(`${id}`)) {
      id = crypto.getRandomValues(idBuffer)[0];
    }
    return `${id}`;
  };

  const receiveMessage = (evt: ResizeEvent) => {
    const data = evt.data;

    if (!data || data.type !== "setHeight" || !iframes.has(data.id)) {
      return;
    }

    const iframe = iframes.get(data.id);

    if ("source" in evt && iframe.contentWindow !== evt.source) {
      return;
    }

    iframe.height = `${data.height}`;
  };

  window.addEventListener("message", receiveMessage);

  document
    .querySelectorAll("iframe.mastodon-embed")
    .forEach((iframe: HTMLIFrameElement) => {
      const id = iframeId();

      iframes.set(id, iframe);

      iframe.scrolling = "no";
      iframe.style.overflow = "hidden";

      iframe.onload = function () {
        iframe.contentWindow.postMessage(
          {
            type: "setHeight",
            id: id
          },
          "*"
        );
      };

      iframe.onload(null);
    });
}
