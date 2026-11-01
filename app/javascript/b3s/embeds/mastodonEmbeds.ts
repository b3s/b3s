type EventData = {
  id: string;
  height: number;
  type: string;
};

type ResizeEvent = Event & {
  data?: EventData;
};

const iframes = new Map<string, HTMLIFrameElement>();

function iframeId() {
  const idBuffer = new Uint32Array(1);
  let id = 0;
  while (id === 0 || iframes.has(`${id}`)) {
    id = crypto.getRandomValues(idBuffer)[0];
  }
  return `${id}`;
}

function receiveMessage(evt: ResizeEvent) {
  const data = evt.data;

  if (!data || data.type !== "setHeight" || !iframes.has(data.id)) {
    return;
  }

  const iframe = iframes.get(data.id);

  if ("source" in evt && iframe.contentWindow !== evt.source) {
    return;
  }

  iframe.height = `${data.height}`;
}

window.addEventListener("message", receiveMessage);

function allowedHosts(): string[] {
  const meta = document.querySelector<HTMLMetaElement>(
    'meta[name="mastodon-embed-hosts"]'
  );
  return meta ? meta.content.split(/\s+/).filter((host) => host) : [];
}

function parseUrl(value: string | undefined): URL | null {
  try {
    return new URL(value);
  } catch {
    return null;
  }
}

function embedUrl(blockquote: HTMLQuoteElement): string | null {
  const container = blockquote.closest<HTMLElement>(
    "div.embed[data-oembed-url]"
  );
  const url = parseUrl(blockquote.dataset.embedUrl);
  const oembedUrl = parseUrl(container?.dataset.oembedUrl);

  if (
    !url ||
    !oembedUrl ||
    url.protocol !== "https:" ||
    url.username ||
    url.password ||
    !url.pathname.endsWith("/embed") ||
    url.host !== oembedUrl.host ||
    !allowedHosts().includes(url.host)
  ) {
    return null;
  }

  return url.toString();
}

function replaceBlockquotes() {
  document
    .querySelectorAll(
      ".post .body div.embed[data-oembed-url] " +
        "blockquote.mastodon-embed[data-embed-url]"
    )
    .forEach((blockquote: HTMLQuoteElement) => {
      const src = embedUrl(blockquote);

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

  document
    .querySelectorAll("iframe.mastodon-embed:not([data-embed-id])")
    .forEach((iframe: HTMLIFrameElement) => {
      const id = iframeId();

      iframes.set(id, iframe);
      iframe.dataset.embedId = id;

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
