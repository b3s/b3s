[![Build](https://github.com/b3s/b3s/workflows/Build/badge.svg)](https://github.com/b3s/b3s/actions)

# B3S

B3S is a modern open-source forum optimized for performance and usability,
written in Ruby on Rails.

## Dependencies

* [Ruby 2.0+](https://www.ruby-lang.org/en/)
* [Bundler](http://bundler.io/)
* [Java](http://www.java.com/en/download/index.jsp)
* libmagic
* [PostgreSQL](http://www.postgresql.org/)

## <a id="configuration"></a> Configuring B3S

Most of the application is configured with a web interface. However, a few 
details must be sorted out before the app starts. The defaults should be 
fine for development, but you need tweak these settings for production use 
with environment variables.

Environment variable  | Required | Info
----------------------|----------|-----------------------------------------------------------------------
DATABASE_URL          | -        | URL to Postgres

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
