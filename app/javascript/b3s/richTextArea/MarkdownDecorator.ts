export default class MarkdownDecorator implements RichText.Decorator {
  blockquote(str: string): RichText.Replacement {
    return [
      "",
      str
        .split("\n")
        .map((l) => `> ${l}`)
        .join("\n"),
      ""
    ];
  }

  bold(str: string): RichText.Replacement {
    return ["**", str, "**"];
  }

  code(str: string, language: string): RichText.Replacement {
    return ["```" + language + "\n", str, "\n```"];
  }

  emphasis(str: string): RichText.Replacement {
    return ["_", str, "_"];
  }

  image(url: string): RichText.Replacement {
    return ["![](", url, ")"];
  }

  link(url: string, name: string): RichText.Replacement {
    return ["[", name, "](" + url + ")"];
  }

  quote(
    html: string,
    username: string,
    permalink: string
  ): RichText.Replacement {
    const content = html.replace(/\n/g, "").replace(/<br[\s/]*>/g, "\n");
    const wrapInBlockquote = (str: string) =>
      str
        .split("\n")
        .map((l) => `> ${l}`)
        .join("\n");
    let cite = `Posted by ${username}:`;
    if (permalink) {
      cite = `Posted by [${username}](${permalink}):`;
    }
    return [
      wrapInBlockquote("<cite>" + cite + "</cite>\n\n" + content) + "\n\n",
      "",
      ""
    ];
  }

  spoiler(str: string): RichText.Replacement {
    return ['<div class="spoiler">', str, "</div>"];
  }
}
