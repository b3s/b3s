import specialKeys from "./specialKeys";

function matchModifier(modifier: string, hotkey: string, event: KeyboardEvent) {
  if (
    (hotkey.includes(`${modifier}+`) && !event[`${modifier}Key`]) ||
    (!hotkey.includes(`${modifier}+`) && event[`${modifier}Key`])
  ) {
    return false;
  }
  return true;
}

function matchKey(hotkey: string, event: KeyboardEvent) {
  const key = hotkey.replace(/(shift|alt|ctrl|meta)\+/, "").toLowerCase();
  if (
    !matchModifier("shift", hotkey, event) ||
    !matchModifier("ctrl", hotkey, event) ||
    !matchModifier("alt", hotkey, event) ||
    !matchModifier("meta", hotkey, event)
  ) {
    return false;
  }
  if (event.keyCode in specialKeys) {
    return specialKeys[event.keyCode] === key;
  } else {
    return String.fromCharCode(event.keyCode).toLowerCase() === key;
  }
}

export default function bindKey(
  hotkey: string,
  fn: (evt: KeyboardEvent) => void
) {
  document.addEventListener("keydown", (evt: KeyboardEvent) => {
    const elem = evt.target as HTMLElement;

    if (
      matchKey(hotkey, evt) &&
      ["INPUT", "TEXTAREA", "SELECT"].indexOf(elem.tagName) === -1
    ) {
      fn(evt);
    }
  });
}
