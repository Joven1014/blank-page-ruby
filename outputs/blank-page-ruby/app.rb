#!/usr/bin/env ruby
# frozen_string_literal: true

require "uri"
require "webrick"

PORT = Integer(ENV.fetch("PORT", "4567"))
BIND = ENV.fetch("BIND", "127.0.0.1")

PAGE = <<~HTML
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="description" content="A deliberately simple web search start page.">
      <title>Blank Page</title>
      <style>
        :root { color-scheme: light; }
        * { box-sizing: border-box; }
        body {
          margin: 0;
          min-height: 100vh;
          display: grid;
          place-items: center;
          padding: 24px;
          font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          color: #000;
          background: #fff;
        }
        main { width: min(680px, 100%); transform: translateY(-8vh); }
        h1 { margin: 0 0 34px; text-align: center; font-size: clamp(2.2rem, 7vw, 4.75rem); letter-spacing: -0.065em; font-weight: 700; }
        form { display: flex; gap: 10px; }
        input {
          min-width: 0;
          flex: 1;
          height: 54px;
          padding: 0 19px;
          border: 2px solid #000;
          border-radius: 14px;
          outline: none;
          background: #fff;
          color: inherit;
          font: inherit;
          font-size: 1rem;
        }
        input::placeholder { color: #555; }
        input:focus { box-shadow: 0 0 0 4px #000; }
        button { height: 54px; padding: 0 20px; border: 2px solid #000; border-radius: 14px; background: #000; color: #fff; font: inherit; font-weight: 700; cursor: pointer; }
        button:hover { background: #fff; color: #000; }
        .hint { margin: 14px 2px 0; text-align: center; color: #000; font-size: .85rem; }
        kbd { padding: 1px 5px; border: 1px solid #000; border-radius: 4px; color: #000; font: inherit; font-size: .78rem; }
      </style>
    </head>
    <body>
      <main>
        <h1>Blank Page</h1>
        <form action="/go" method="get" role="search">
          <input type="search" name="q" autocomplete="off" autofocus placeholder="Search the web or enter a URL" aria-label="Search the web or enter a URL">
          <button type="submit">Search</button>
        </form>
        <p class="hint">Press <kbd>Enter</kbd> to search. URLs open directly.</p>
      </main>
    </body>
  </html>
HTML

def destination(query)
  text = query.to_s.strip
  return nil if text.empty?

  looks_like_url = text.match?(%r{\A(?:https?://|localhost(?::\d+)?(?:/|\z)|(?:[\w-]+\.)+[a-z]{2,}(?:/|\z))}i)
  return text.match?(%r{\Ahttps?://}i) ? text : "https://#{text}" if looks_like_url

  "https://www.google.com/search?q=#{URI.encode_www_form_component(text)}"
end

server = WEBrick::HTTPServer.new(
  Port: PORT,
  BindAddress: BIND,
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
  AccessLog: []
)

server.mount_proc "/" do |_request, response|
  response["Content-Type"] = "text/html; charset=utf-8"
  response.body = PAGE
end

server.mount_proc "/go" do |request, response|
  target = destination(request.query["q"])
  if target
    response.status = 302
    response["Location"] = target
  else
    response.status = 302
    response["Location"] = "/"
  end
end

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }

puts "Blank Page is running at http://#{BIND}:#{PORT}"
server.start
