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
        link.innerHTML =
          "<video autoplay loop muted>" +
          `<source type="video/webm" src="${baseUrl}.webm">` +
          `<source type="video/mp4" src="${baseUrl}.mp4"></video>`;

        img.replaceWith(link);
      }
    });
  }
}
