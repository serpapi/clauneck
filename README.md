<h1 align="center">Clauneck</h1>

<div align="center">

  <a href="">[![Gem Version][gem-shield]][gem-url]</a>
  <a href="">[![Contributors][contributors-shield]][contributors-url] </a>
  <a href="">[![Forks][forks-shield]][forks-url]</a>
  <a href="">[![Stargazers][stars-shield]][stars-url]</a>
  <a href="">[![Issues][issues-shield]][issues-url]</a>
  <a href="">[![Issues][issuesclosed-shield]][issuesclosed-url]</a>
  <a href="">[![MIT License][license-shield]][license-url]</a>

</div>

<p align="center">
  <img src="https://user-images.githubusercontent.com/73674035/251452240-e80b12d7-0c7a-40fc-9cbc-bb3bcb7986a8.png" alt="Clauneck Information Scraper" width="50%"/>
</p>


`Clauneck` is a Ruby gem designed to scrape specific information from a series of URLs, either directly provided or fetched from Google search results via [SerpApi's Google Search API](https://serpapi.com/search-api). It extracts and matches patterns such as email addresses and social media handles from the web pages, and stores the results in a CSV file.

Unlike Google Chrome extensions that need you to visit webpages one by one, Clauneck excels in bringing the list of websites to you by leveraging [SerpApi’s Google Search API](https://serpapi.com/search-api).

- [Cold Email Marketing with Open-Source Email Extractor](https://serpapi.com/blog/cold-email-marketing-with-open-source-email-extractor/): A Blog Post about the usecase of the tool

---


## The End Result

The script will write the results in a CSV file. If it cannot find any one of the information on a website, it will label it as `null`. For unknown errors happening in-between (connection errors, encoding errors, etc.) the fields will be filled with as `error`.


| Website             | Information          | Type of Information |
|---------------------|----------------------|-----------------|
| serpapi.com     | `contact@serpapi.com`  | Email           |
| serpapi.com     | `serpapicom`           | Instagram       |
| serpapi.com     | `serpapicom`           | Facebook        |
| serpapi.com     | `serp_api`             | Twitter         |
| serpapi.com     | `null`                 | Tiktok          |
| serpapi.com     | `channel/UCUgIHlYBOD3yA3yDIRhg_mg` | Youtube |
| serpapi.com     | `serpapi`              | Github          |
| serpapi.com     | `serpapi`              | Medium          |

---

## Prerequisites
Since [SerpApi](https://serpapi.com) offers free credits that renew every month, and the user can access a list of free public proxies online, this tool’s pricing is technically free. You may extract data from approximately 10,000 pages (100 results in 1 page, and up to 100 pages) with a free account from [SerpApi](https://serpapi.com).

- For collecting URLs to scrape, one of the following is required:
  - SerpApi API Key: You may [Register to Claim Free Credits](https://serpapi.com/users/sign_up)
  - List of URLs in a text document (The URLs should be Google web cache links that start with `https://webcache.googleusercontent.com`)
- For scraping URLs, one of the following is required:
  - List of Proxies in a text document (You may use public proxies. Only HTTP proxies are accepted.)
  - Rotating Proxy IP

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'clauneck'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install clauneck
```

---

## Basic Usage

You can use `Clauneck` as a command line tool or within your Ruby scripts. 

### Basic Command line usage

In the command line, use the `clauneck` command with options as follows:

```
clauneck --api_key YOUR_SERPAPI_KEY --output results.csv --q "site:*.ai AND inurl:/contact OR inurl:/contact-us"
```

### Basic Ruby script usage

In your Ruby script, call `Clauneck.run` method:

```ruby
require 'clauneck'

api_key = "<SerpApi API Key>" # Visit https://serpapi.com/users/sign_up to get free credits.
params = {
  "q": "site:*.ai AND inurl:/contact OR inurl:/contact-us"
}

Clauneck.run(api_key: api_key, params: params)
```

---

## Advanced Usage

### Using Advanced Search Parameters
You can visit the Documentation for [SerpApi's Google Search API](https://serpapi.com/search-api) to get insight on which parameters you can use to construct searches.

<img width="1470" alt="image" src="https://user-images.githubusercontent.com/73674035/251473233-4be601c1-846b-4ae6-bb65-4c45aa22667d.png">

### Using Advanced Search Operators

Google allows different search operators in queries to be made. This enhances your abilty to customize your search and get more precise results. For example, this search query:
`"site:*.ai AND inurl:/contact OR inurl:/contact-us"`
will search for websites ending with `.ai` and at `/contact` or `/contact-us` paths.

You may check out [Google Search Operators: The Complete List (44 Advanced Operators)](https://ahrefs.com/blog/google-advanced-search-operators/) for a list of more operators

### Using Proxies for Scraping in a Text Document
You can utilize your own proxies for scraping web caches of the links you have acquired. Only HTTP proxies are accepted. The proxies should be in the following format
```
http://username:password@ip:port
http://username:password@another-ip:another-port
```
or if they are public proxies:
```
http://ip:port
http://another-ip:another-port
```

You can add --proxy option in the command line to utilize the file:
```
clauneck --api_key YOUR_SERPAPI_KEY --proxy proxies.txt --output results.csv --q "site:*.ai AND inurl:/contact OR inurl:/contact-us"
```

or use the rotating proxy link directly:
```
clauneck --api_key YOUR_SERPAPI_KEY --proxy "http://username:password@ip:port" --output results.csv --q "site:*.ai AND inurl:/contact OR inurl:/contact-us"
```

You may also use it in a script:
```rb
api_key = "<SerpApi API Key>" # Visit https://serpapi.com/users/sign_up to get free credits.
params = {
  "q": "site:*.ai AND inurl:/contact OR inurl:/contact-us"
}
proxy = "proxies.txt"

Clauneck.run(api_key: api_key, params: params, proxy: proxy)
```

or directly use the rotating proxy link:
```rb
api_key = "<SerpApi API Key>" # Visit https://serpapi.com/users/sign_up to get free credits.
params = {
  "q": "site:*.ai AND inurl:/contact OR inurl:/contact-us"
}
proxy = "http://username:password@ip:port"

Clauneck.run(api_key: api_key, params: params, proxy: proxy)
```

The System IP Address will be used if no proxy is provided. The user can use System IP for small-scale projects. But it is not recommended.

### Using Google Search URL to Scrape links with SerpApi

Instead of providing search parameters, the user can directly feed a Google Search URL for the web cache links to be collected by [SerpApi's Google Search API](https://serpapi.com/search-api).

### Using URLs to Scrape in a Text Document

The user may utilize their own list of URLs to be scraped. The URLs should start with `https://webcache.googleusercontent.com`, and be added to each line. For example:

```
https://webcache.googleusercontent.com/search?q=cache:LItv_3DO2N8J:https://serpapi.com/&cd=10&hl=en&ct=clnk&gl=cy
https://webcache.googleusercontent.com/search?q=cache:_gaXFsYVmCgJ:https://serpapi.com/search-api&cd=9&hl=en&ct=clnk&gl=cy
```

You can find cached links manually from Google Searches as shown below:

![image](https://user-images.githubusercontent.com/73674035/251461862-5cc1e279-9d5c-4885-aebd-317512ae62ea.png)

---

## Options

`Clauneck` accepts the following options:

- `--api_key`: Your SerpApi key. It is required if you're not providing the `--urls` option.
- `--proxy`: Your proxy file or proxy URL. Defaults to system IP if not provided.
- `--pages`: The number of pages to fetch from Google using SerpApi. Defaults to `1`.
- `--output`: The CSV output file where to store the results. Defaults to `output.csv`.
- `--google_url`: The Google URL that contains the webpages you want to scrape. It should be a Google Search Results URL.
- `--urls`: The URLs you want to scrape. If provided, the gem will not fetch URLs from Google.
- `--help`: Shows the help message and exits.

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serpapi/clauneck.

---

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[gem-shield]: https://img.shields.io/gem/v/clauneck.svg
[gem-url]: https://rubygems.org/gems/clauneck
[contributors-shield]: https://img.shields.io/github/contributors/serpapi/clauneck.svg
[contributors-url]: https://github.com/serpapi/clauneck/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/serpapi/clauneck.svg
[forks-url]: https://github.com/serpapi/clauneck/network/members
[stars-shield]: https://img.shields.io/github/stars/serpapi/clauneck.svg
[stars-url]: https://github.com/serpapi/clauneck/stargazers
[issues-shield]: https://img.shields.io/github/issues/serpapi/clauneck.svg
[issues-url]: https://github.com/serpapi/clauneck/issues
[issuesclosed-shield]: https://img.shields.io/github/issues-closed/serpapi/clauneck.svg
[issuesclosed-url]: https://github.com/serpapi/clauneck/issues?q=is%3Aissue+is%3Aclosed
[license-shield]: https://img.shields.io/github/license/serpapi/clauneck.svg
[license-url]: https://github.com/serpapi/clauneck/blob/master/LICENSE
