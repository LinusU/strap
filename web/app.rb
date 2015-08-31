require "sinatra"
require "omniauth-github"
require "octokit"
require "awesome_print" if ENV["RACK_ENV"] == "development"

GITHUB_KEY = ENV["GITHUB_KEY"]
GITHUB_SECRET = ENV["GITHUB_SECRET"]
SESSION_SECRET = ENV["SESSION_SECRET"]

set :sessions, secret: SESSION_SECRET

use OmniAuth::Builder do
  provider :github, GITHUB_KEY, GITHUB_SECRET, scope: "user:email,repo"
end

before %r{^(?!/auth/github)} do
  redirect to "/auth/github" unless session[:auth]
end

get "/auth/github/callback" do
  session[:auth] = request.env["omniauth.auth"]
  redirect to "/"
end

get "/" do
  @title = "Strap"
  @text = <<-EOS
Strap is a script to bootstrap a minimal OS X development system. This does not assume you're doing Ruby/Rails/web development but installs the minimal set of software every OS X developer will want.

To Strap your system:
<ol>
  <li><a href="/strap.sh">Download the <code>strap.sh</code></a> that's been customised for your GitHub user (or <a href="/strap.sh?text=1">view it</a> first).</li>
  <li>Run Strap in Terminal.app with <code>bash ~/Downloads/strap.sh</code>.</li>
  <li>If something failed run Strap with more debugging output in Terminal.app with <code>bash ~/Downloads/strap.sh --debug</code></li>
  <li>Delete the customised <code>strap.sh</code></a> (it has a GitHub token in it) in Terminal.app with <code>rm -f ~/Downloads/strap.sh</code></a></li>
  <li>Install additional software with <code>brew install</code> and <code>brew cask install</code>.</li>
</ol>
EOS
  erb :root
end

get "/strap.sh" do
  auth = session[:auth]
  content_type = params["text"] ? "text/plain" : "application/octet-stream"

  content = IO.read(File.expand_path("#{File.dirname(__FILE__)}/../bin/strap.sh"))
  content.gsub!(/^STRAP_GIT_NAME=$/,  "STRAP_GIT_NAME='#{auth["info"]["name"]}'")
  content.gsub!(/^STRAP_GIT_EMAIL=$/, "STRAP_GIT_EMAIL='#{auth["info"]["email"]}'")
  content.gsub!(/^STRAP_GIT_TOKEN=$/, "STRAP_GIT_TOKEN='#{auth["credentials"]["token"]}'")

  erb content, content_type: content_type
end
