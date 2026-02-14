[![Push](https://github.com/b3s/b3s/actions/workflows/push.yml/badge.svg)](https://github.com/b3s/b3s/actions/workflows/push.yml)

# B3S

B3S is a modern open-source forum optimized for performance and usability,
written in Ruby on Rails.

## Dependencies

* [Ruby 4.0+](https://www.ruby-lang.org/en/)
* [Node.js 24+](https://nodejs.org/)
* [pnpm](https://pnpm.io/)
* [PostgreSQL](https://www.postgresql.org/)
* libvips

## Deployment

The following environment variables are required for a production deployment:

Environment variable   | Info
-----------------------|------------------
RAILS_MASTER_KEY       | Rails master key
DATABASE_URL           | URL to Postgres
OEMBED_FACEBOOK_TOKEN  | Facebook oEmbed access token
WEB_CONCURRENCY        | Puma worker count (default: 2)
NGINX_CACHE_MAX_SIZE   | Max size of nginx image cache (default: 2g)

## Credits

Thanks to the members of the B3S community for feedback, ideas and
encouragement, names far too many to be mentioned. Napkin was written by
Branden Hall of [Automata Studios](http://automatastudios.com/).

## License

Copyright (c) 2008 Inge Jørgensen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
