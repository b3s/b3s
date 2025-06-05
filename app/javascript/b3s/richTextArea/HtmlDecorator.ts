export default class HtmlDecorator implements RichText.Decorator {
  blockquote(str: string): RichText.Replacement {
    return ["<blockquote>", str, "</blockquote>"];
  }

  bold(str: string): RichText.Replacement {
    return ["<b>", str, "</b>"];
  }

  code(str: string, language: string): RichText.Replacement {
    return ["```" + language + "\n", str, "\n```"];
  }

  emphasis(str: string): RichText.Replacement {
    return ["<i>", str, "</i>"];
  }

  image(url: string): RichText.Replacement {
    return ['<img src="', url, '">'];
  }

  link(url: string, name: string): RichText.Replacement {
    return ['<a href="' + url + '">', name, "</a>"];
  }

  quote(
    html: string,
    username: string,
    permalink: string
  ): RichText.Replacement {
    const content = html.replace(/\n/g, "").replace(/<br[\s/]*>/g, "\n");
    let cite = `Posted by ${username}:`;
    if (permalink) {
      cite = `Posted by <a href="${permalink}">${username}</a>:`;
    }
    return [
      "<blockquote><cite>" +
        cite +
        "</cite> " +
        content +
        "</blockquote>" +
        "\n\n",
      "",
      ""
    ];
  }

  spoiler(str: string): RichText.Replacement {
    return ['<div class="spoiler">', str, "</div>"];
  }
}
