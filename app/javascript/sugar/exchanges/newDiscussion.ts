import readyHandler from "../../lib/readyHandler";

type Discussion = {
  id: number;
  title: string;
  posts_count: number;
};

const stopwords = [
  "i",
  "a",
  "about",
  "an",
  "and",
  "are",
  "as",
  "at",
  "by",
  "for",
  "from",
  "has",
  "have",
  "how",
  "in",
  "is",
  "it",
  "la",
  "my",
  "of",
  "on",
  "or",
  "that",
  "the",
  "this",
  "to",
  "was",
  "what",
  "when",
  "where",
  "who",
  "will",
  "with",
  "the"
];

readyHandler.ready(() => {
  const discussionForm =
    document.querySelector<HTMLFormElement>("#new_discussion");
  if (!discussionForm) return;

  const titleInput = discussionForm.querySelector<HTMLInputElement>(".title");
  if (!titleInput) return;

  const searchResults = document.createElement("div");
  searchResults.className = "title_search";
  searchResults.style.display = "none";
  titleInput.after(searchResults);

  let previousValue = "";
  let keypressInterval: number | undefined;

  titleInput.addEventListener("keydown", () => {
    setTimeout(searchDiscussions, 10);
  });

  const searchDiscussions = () => {
    const currentValue = titleInput.value;
    if (!currentValue || previousValue === currentValue) return;

    previousValue = currentValue;
    searchResults.classList.add("loading");
    searchResults.textContent = "Searching for similar discussions...";
    searchResults.style.display = "block";

    if (keypressInterval) {
      clearInterval(keypressInterval);
    }

    const performSearch = () => {
      const words = currentValue
        .toLowerCase()
        .split(/\s+/)
        .filter((word) => !stopwords.includes(word))
        .map((word) => word.replace(/[!~^=$*[\]{}]/, ""));

      const query = words.join(" | ");
      const searchUrl = "/discussions/search.json";

      fetch(`${searchUrl}?q=${encodeURIComponent(query)}`)
        .then((response) => response.json())
        .then((discussions: Discussion[]) => {
          searchResults.classList.remove("loading");

          if (discussions.length === 0) {
            searchResults.textContent = "";
            searchResults.style.display = "none";
            return;
          }

          let output =
            "<h4>Similar discussions found. Maybe you should check them out before posting?</h4>";

          discussions.slice(0, 10).forEach((discussion) => {
            output += `
              <a href="/discussions/${discussion.id}" class="discussion">
                ${discussion.title}
                <span class="posts_count">${discussion.posts_count} posts</span>
              </a>`;
          });

          if (discussions.length > 10) {
            output += `<a href="/search?q=${encodeURIComponent(query)}">Show all results</a>`;
          }

          searchResults.innerHTML = output;
          searchResults.style.display = "none";
          requestAnimationFrame(() => {
            searchResults.style.display = "block";
          });
        });

      clearInterval(keypressInterval);
    };

    keypressInterval = window.setInterval(performSearch, 500);
  };
});
