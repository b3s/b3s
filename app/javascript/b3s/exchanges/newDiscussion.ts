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

          const heading = document.createElement("h4");
          heading.textContent =
            "Similar discussions found. Maybe you should check them out before posting?";
          const results: HTMLElement[] = [heading];

          discussions.slice(0, 10).forEach((discussion) => {
            const link = document.createElement("a");
            link.href = `/discussions/${discussion.id}`;
            link.className = "discussion";

            const postsCount = document.createElement("span");
            postsCount.className = "posts_count";
            postsCount.textContent = `${discussion.posts_count} posts`;

            link.append(` ${discussion.title} `, postsCount);
            results.push(link);
          });

          if (discussions.length > 10) {
            const allResults = document.createElement("a");
            allResults.href = `/search?q=${encodeURIComponent(query)}`;
            allResults.textContent = "Show all results";
            results.push(allResults);
          }

          searchResults.replaceChildren(...results);
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
