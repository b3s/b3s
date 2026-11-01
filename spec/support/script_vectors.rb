# frozen_string_literal: true

SCRIPT_VECTORS = {
  "a script tag" => "<script>alert('foo');</script>",
  "a mixed case script tag" => "<ScRiPt>alert(1)</sCrIpT>",
  "a script tag inside svg" => "<svg><script>alert(document.domain)</script></svg>",
  "a script tag inside math" => "<math><mi><script>alert(1)</script></mi></math>",
  "an svg animate setting href" =>
    '<svg><a><animate attributeName="href" values="0;javascript:alert(1)"/>' \
    '<text x="20" y="20">x</text></a></svg>',
  "an svg link with xlink:href" =>
    '<svg><a xlink:href="javascript:alert(1)"><text>x</text></a></svg>',
  "an svg with onload" => '<svg onload="alert(1)">',
  "math with an href" => '<math href="javascript:alert(1)"><mi>x</mi></math>',
  "an iframe with srcdoc" =>
    '<iframe srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
  "an iframe with a data URI" =>
    '<iframe src="data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;"></iframe>',
  "an iframe with a javascript URL" => '<iframe src="javascript:alert(1)"></iframe>',
  "a javascript URL" => "<a href=\"javascript:alert('hi');\">link</a>",
  "a mixed case javascript URL" => '<a href="JaVaScRiPt:alert(1)">link</a>',
  "a javascript URL with an encoded tab" => '<a href="java&#9;script:alert(1)">link</a>',
  "a javascript URL with an encoded newline" => '<a href="java&#x0A;script:alert(1)">link</a>',
  "a javascript URL with a literal tab" => "<a href=\"java\tscript:alert(1)\">link</a>",
  "a javascript URL with leading control characters" =>
    '<a href="&#1;&#31; javascript:alert(1)">link</a>',
  "a javascript URL with an encoded colon" => '<a href="javascript&colon;alert(1)">link</a>',
  "a javascript URL with encoded letters" =>
    '<a href="&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;alert(1)">link</a>',
  "a javascript URL with unterminated entities" =>
    '<a href="&#0000106&#0000097vascript:alert(1)">link</a>',
  "a vbscript URL" => '<a href="vbscript:msgbox(1)">link</a>',
  "a data URL link" => '<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">link</a>',
  "a javascript image source" => '<img src="javascript:alert(1)">',
  "an event handler" => "<img src=\"image.jpg\" onload=\"alert('hi');\">",
  "a mixed case event handler" => '<img src="x" OnErRoR="alert(1)">',
  "a formaction attribute" =>
    '<form><button formaction="javascript:alert(1)">x</button></form>',
  "a button with formaction" => '<button formaction="javascript:alert(1)">x</button>',
  "an input with formaction" => '<input type="image" formaction="javascript:alert(1)">',
  "a base tag" => '<base href="javascript:alert(1)//">',
  "a meta refresh" => '<meta http-equiv="refresh" content="0;url=javascript:alert(1)">',
  "a link tag" => '<link rel="stylesheet" href="theme.css">',
  "a style tag" => "<style>@import 'javascript:alert(1)'; body { background: red }</style>",
  "a style tag inside svg" => "<svg><style>*{x:expression(alert(1))}</style></svg>",
  "an object tag" => '<object data="javascript:alert(1)"></object>',
  "an embed tag" => '<embed src="javascript:alert(1)">',
  "a noscript tag" => '<noscript><p title="</noscript><img src=x onerror=alert(1)>"></noscript>',
  "a template tag" => "<template><script>alert(1)</script></template>",
  "a video poster" => '<video poster="javascript:alert(1)"></video>',
  "a blockquote cite" => '<blockquote cite="javascript:alert(1)">x</blockquote>',
  "a comment breaking out" => "<!--><script>alert(1)</script>-->",
  "a mangled script tag" => "<scr<script>ipt>alert(1)</script>",
  "a script with a slash" => "<script/x>alert(1)</script>"
}.freeze
