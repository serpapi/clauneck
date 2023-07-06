#!/usr/bin/env ruby

require './lib/clauneck'

api_key = "<SerpApi API Key>" # Visit https://serpapi.com/users/sign_up to get free credits.
proxy = "proxies.txt" # Only HTTP Proxies are accepted
params = {
  "q": "site:*.ai AND inurl:/contact OR inurl:/contact-us"
}

Clauneck.run(api_key: api_key, params: params, proxy: proxy, pages: 2)
