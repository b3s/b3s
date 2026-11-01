const htmlEntities: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#39;"
};

export function squish(text: string) {
  return text.replace(/\s+/g, " ").trim();
}

export function escapeHtml(text: string) {
  return text.replace(/[&<>"']/g, (c) => htmlEntities[c]);
}

export function escapeMarkdown(text: string) {
  return escapeHtml(text)
    .replace(/\\/g, "&#92;")
    .replace(/[`*_~[\]]/g, "\\$&");
}

export function escapeMarkdownUrl(url: string) {
  return url.replace(/[()\s]/g, (c) =>
    c === "(" ? "%28" : c === ")" ? "%29" : encodeURIComponent(c)
  );
}
