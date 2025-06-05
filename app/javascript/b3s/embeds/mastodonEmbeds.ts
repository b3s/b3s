type EventData = {
  id: string;
  height: number;
  type: string;
};

type ResizeEvent = Event & {
  data?: EventData;
};

export default function mastodonEmbeds() {
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
