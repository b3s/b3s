export default function spoiler(elem: HTMLElement) {
  elem.querySelectorAll(".spoiler").forEach((spoiler) => {
    spoiler.addEventListener("click", () => {
      spoiler.classList.toggle("revealed");
    });
  });
}
