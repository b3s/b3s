const testElem = document.createElement("video");

function canPlay(type: string) {
  return testElem.canPlayType && testElem.canPlayType(type);
}

export default function gifvVideos() {
  if (canPlay("video/webm") || canPlay("video/mp4")) {
    document.querySelectorAll("img").forEach((img) => {
      if (img.src.match(/imgur\.com\/.*\.(gif)$/i)) {
        img.src += "v";
      }
      if (img.src.match(/\.gifv$/)) {
        const baseUrl = img.src.replace(/\.gifv$/, "");

        const link = document.createElement("a");
        link.href = `${baseUrl}.gif`;
        const video = document.createElement("video");
        ["autoplay", "loop", "muted"].forEach((attribute) =>
          video.setAttribute(attribute, "")
        );
        [
          ["video/webm", "webm"],
          ["video/mp4", "mp4"]
        ].forEach(([type, extension]) => {
          const source = document.createElement("source");
          source.type = type;
          source.src = `${baseUrl}.${extension}`;
          video.append(source);
        });
        link.append(video);

        img.replaceWith(link);
      }
    });
  }
}
