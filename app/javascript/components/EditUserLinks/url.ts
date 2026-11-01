const urlPattern =
  /^(https?:\/\/)?(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\/\S*)?$/i;

export function normalizeUrl(url: string): string {
  const stripped = url.trim();
  if (stripped && !/^https?:\/\//i.test(stripped)) {
    return `https://${stripped}`;
  }
  return stripped;
}

export function validUrl(url: string): boolean {
  return urlPattern.test(url.trim());
}
