export function getSelection(elem: HTMLTextAreaElement) {
  const { selectionStart, selectionEnd, value } = elem;
  return value.substr(selectionStart, selectionEnd - selectionStart);
}

export function replaceSelection(
  textarea: HTMLTextAreaElement,
  prefix: string,
  replacement: string,
  postfix: string
) {
  const { selectionStart, selectionEnd, value } = textarea;

  textarea.value =
    value.substr(0, selectionStart) +
    prefix +
    replacement +
    postfix +
    value.substr(selectionEnd, value.length);

  textarea.focus({ preventScroll: true });
  textarea.setSelectionRange(
    selectionStart + prefix.length,
    selectionStart + prefix.length + replacement.length
  );
}
