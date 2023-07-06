require 'faraday'
require 'json'
require 'optparse'
require 'concurrent'
require 'thread'
require 'csv'
require 'zlib'
require 'stringio'
require 'brotli'

USER_AGENTS = [
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 OPR/97.0.0.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 OPR/98.0.0.0",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/113.0.1774.42",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1 Safari/605.1.15",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/114.0",
]

MAXIMUM_RETRIES = 5

REGEXES = [
  ["Email", /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/],
  ["Instagram", /(?:www\.)?(?:instagram)\.com\/([a-zA-Z0-9_\-]+)/],
  ["Facebook", /(?:www\.)?(?:instagram)\.com\/([a-zA-Z0-9_\-]+)/],
  ["Twitter", /(?:www\.)?(?:twitter)\.com\/([a-zA-Z0-9_\-]+)/],
  ["Tiktok", /(?:www\.)?(?:tiktok.com)\.com\/(@[a-zA-Z0-9_\-]+)/],
  ["Youtube", /(?:www\.)?(?:youtube)\.com\/(channel\/[a-zA-Z0-9_\-]+)/],
  ["Github", /(?:www\.)?(?:github)\.com\/([a-zA-Z0-9_\-]+)/],
  ["Medium", /(?:www\.)?(?:medium)\.com\/([a-zA-Z0-9_\-]+)/],
]

module Clauneck
  class << self
    def run(api_key: nil, proxy: nil, pages: nil, output: nil, google_url: nil, params: {}, urls: nil)
      options = {
        api_key: api_key,
        proxy: proxy,
        pages: pages,
        output: output,
        google_url: google_url,
        params: params,
        urls: urls
      }

      if options.values.all? { |v| v.nil? || v.empty? }
        options = parse_options
      else
        options[:proxies] = get_proxies proxy
      end
    
      if options[:urls].nil? || options[:urls].empty?
        pages = fetch_pages_via_serpapi(options[:api_key], options[:google_url], options[:params], options[:pages])
        links = parse_pages(pages)
      else
        # Use existing URLs
        links = get_urls(urls)
      end

      fetch_and_write_information(links, options[:proxies], options[:output])
    end

    private

    def parse_options
      options = { params: {} }
      remaining = []
    
      while arg = ARGV.shift
        if arg == '--help'
          show_help
          exit
        elsif arg.start_with?('--') && !known_option?(arg)
          key, value = arg.split('=')
          key.gsub!(/^-*/, '') # Remove leading dashes
          if value.nil? # In case option passed as "--option value" instead of "--option=value"
            value = ARGV.shift
          end
          options[:params][key] = value
        else
          remaining << arg
        end
      end
    
      parser = OptionParser.new do |opts|
        opts.on('--api_key API_KEY') { |v| options[:api_key] = v }
        opts.on('--proxy PROXY') { |v| options[:proxy] = v }
        opts.on('--pages PAGES') { |v| options[:pages] = v.to_i }
        opts.on('--output OUTPUT') { |v| options[:output] = v }
        opts.on('--google_url GOOGLE_URL') { |v| options[:google_url] = v }
        opts.on('--urls URLS') { |v| options[:urls] = v }
        opts.on('--help', 'Prints this help message') do
          show_help(opts)
          exit
        end
      end
      parser.parse!(remaining)
    
      options[:pages] ||= 1
      options[:output] ||= 'output.csv'
      options[:proxies] = get_proxies(options[:proxy])
    
      if requirements(options)
        options
      else
        puts <<-HELP
    Warning: Use at least one of the required parameters. Use `clauneck --help`` to get more information.
    HELP
        exit(1)
      end
    end
    
    def known_option?(arg)
      ['--api_key', '--proxy', '--pages', '--output', '--google_url', '--urls'].any? { |opt| arg.start_with?(opt) }
    end

    def requirements(options)
      cond_1 = options[:params] && options[:params].keys.any? {|k| k == "api-key"}
      cond_2 = options[:urls]
      cond_1 || cond_2
    end
    
    def show_help(opts = nil)
      puts opts if opts
      puts <<-HELP
    Usage: clauneck [options]
    
    Options:
        --api_key API_KEY           Set the SerpApi API key (Required if you don't provide `--urls` option)
        --proxy PROXY               Set the proxy file or proxy url (Default: System IP)
        --pages PAGES               Set the number of pages to be gathered from Google using SerpApi (Default: 1)
        --output OUTPUT             Set the csv output file (Default: output.csv)
        --google_url GOOGLE_URL     Set the Google URL that contains the webpages you want to scrape
        --urls URLS                 Set the URLs you want to scrape information from (Required if you don't provide `--api-key` option)
        --help                      Prints this help message
      HELP
      exit(1)
    end 

    def get_urls(url)
      return [] unless url
      return url if proxy.is_a?(Array)
      return [File.read(url).strip] if url.end_with?('.txt')

      [url]
    end

    def get_proxies(proxy)
      return [] unless proxy
      return proxy if proxy.is_a?(Array)
      return File.readlines(proxy).map(&:strip) if proxy.end_with?('.txt')

      [proxy]
    end

    def build_url(api_key, google_url, params, page)
      num = params['num'] || 100 || google_url.scan(/num=(\d+)\&|num=(\d+)$/)&.dig(0, 0)
      base = google_url ? google_url.gsub('google', 'serpapi') : "https://serpapi.com/search"
      params = params.merge({ start: page * num, num: num, api_key: api_key, no_cache: true, async: true })
      "#{base}?#{URI.encode_www_form(params)}"
    end

    def fetch_pages_via_serpapi(api_key, google_url, params, pages)
      pages = 1 if pages == nil
      pool = Concurrent::FixedThreadPool.new(10)
      futures = []
    
      urls = (0...pages).map { |page| build_url(api_key, google_url, params, page) }
    
      urls.each do |url|
        futures << Concurrent::Future.execute(executor: pool) do
          response = Faraday.get(url).body
    
          begin
            data = JSON.parse(response)
          rescue JSON::ParserError => e
            puts "Failed to parse JSON response from #{url} with error: #{e.message}"
            next
          end
    
          while data["search_metadata"]["status"] == "Processing"
            sleep(0.1)
            endpoint = data["search_metadata"]["json_endpoint"]
            response = Faraday.get(endpoint).body
    
            begin
              data = JSON.parse(response)
            rescue JSON::ParserError => e
              puts "Failed to parse JSON response from #{endpoint} with error: #{e.message}"
              next
            end
          end
    
          data
        end
      end
    
      puts "Using SerpApi to collect webpages..."
      futures.map(&:value)
    end

    def fetch_and_write_information(links, proxies, output)
      csv_mutex = Mutex.new
      total_links = links.size
      processed_links = Concurrent::AtomicFixnum.new(0)
    
      puts "Total links to process: #{total_links}"
    
      output = "output.csv" if output == nil
      CSV.open(output, 'w') do |csv|
        links.each_slice(5) do |links_slice|
          link_futures = []
          links_slice.each do |link|
            action = proc {
              page_body = nil
              retry_count = 0
              link = link.sub(/^https:\/\//, 'http://')
              while retry_count < MAXIMUM_RETRIES
                proxies_cycle = proxies.cycle.take(1)
                user_agents_cycle = USER_AGENTS.cycle.take(1)
                
                begin
                  page_body = fetch_link(link, proxies_cycle, user_agents_cycle)
                rescue => e
                  puts "Error: #{e.message}; #{processed_links.value} out of #{total_links}"
                end

                if page_body
                  break
                else
                  retry_count += 1
                  puts "Retrying #{retry_count} times..."
                end
              end
              
              information_arr, type_arr = parse_for_information(page_body)
              
              domain = link&.scan(/http:\/\/webcache\.googleusercontent\.com\/search\?q=cache:.*:\/\/([^\/]+)/)&.dig(0,0)

              csv_mutex.synchronize do
                information_arr.each_with_index do |information, index|
                  csv << [domain, information, type_arr[index]]
                  csv.flush
                end
              end
    
              processed_links.increment

              if information_arr.all? {|element| element == ["null"]}
                puts "Couldn't find information on the link: #{processed_links.value} out of #{total_links}"
              elsif information_arr.all? {|element| element == ["error"]}
                puts "There was an error in fetching the webcache: #{processed_links.value} out of #{total_links}"
              else
                puts "Processed link: #{processed_links.value} out of #{total_links}"
              end
            }

            link_futures << Thread.new(&action)
          end
          link_futures.each(&:join)
        end
      end
    end    

    def fetch_link(link, proxies_cycle, user_agents_cycle)
      user_agent = user_agents_cycle.sample
      headers = {
        'User-Agent' => user_agent,
        'Accept-Encoding' => 'gzip, deflate, br',
        'Host' => 'webcache.googleusercontent.com'
      }
    
      if proxies_cycle && !proxies_cycle.empty?
        proxy = proxies_cycle.sample
        protocol, username, password, addr, port = parse_proxy(proxy)
        f_proxy = Faraday::ProxyOptions.new(uri=proxy, user=user, password=password)
        conn = Faraday.new(url: link, ssl: { verify: false }, proxy: f_proxy) do |faraday|
          faraday.headers = headers
          faraday.options.timeout = 10
          faraday.adapter Faraday.default_adapter
        end
      else
        conn = Faraday.new(url: link, ssl: { verify: false }) do |faraday|
          faraday.headers = headers
          faraday.options.timeout = 5
          faraday.adapter Faraday.default_adapter
        end
      end
    
      response = conn.get
      if response.status == 200
        response_body = handle_compressed_response(response)
        return response_body
      end
    end

    def parse_pages(pages)
      if !pages.empty? && pages != nil
        pages.flat_map do |page|
          if page
            page['organic_results']&.map { |r| r.dig('cached_page_link') }
          else
            puts <<-HELP
            Warning: There's a problem connecting to SerpApi. Make sure you have used the correct API Key.
            HELP
            exit(1)
          end
        end.compact
      else
        puts <<-HELP
        Warning: There's a problem connecting to SerpApi. Make sure you have used the correct API Key.
        HELP
        exit(1)
      end
    end
    
    def parse_proxy(proxy)
      protocol, userinfo_and_hostinfo = proxy.split('://')
      userinfo, hostinfo = userinfo_and_hostinfo.split('@')
      username, password = userinfo.split(':')
      addr, port = hostinfo&.split(':')
      if addr == nil && port == nil
        addr, port = username, password
        username, password = nil, nil
      end

      [protocol, username, password, addr, port]
    end

    def parse_for_information(body)
      information_arr = []
      type_arr = []

      REGEXES.each_with_index do |regex, index|
        information = begin
          body&.scan(regex[1])&.uniq&.compact&.flatten
        rescue ArgumentError
          nil
        end
        information.reject! {|item| item[/\.png|\.jpg|\.jpeg|\.gif|\.webp/]} if information
        information = "error" if information == nil
        information = "null" if information.empty?
        information_arr << information
        type = []
        if information != "null" && information != "error"
          information.each {|i| type << regex[0]}
        else
          type = regex[0]
        end

        type_arr << type
      end

      return information_arr.flatten, type_arr.flatten
    end

    def handle_compressed_response(response)
      if response['content-encoding'] == 'br'
        body = Brotli.inflate(response.body)
      elsif response['content-encoding'] == 'gzip'
        gzip_reader = Zlib::GzipReader.new(StringIO.new(response.body))
        body = gzip_reader.read
        gzip_reader.close
      elsif response['content-encoding'] == 'deflate'
        body = Zlib::Inflate.inflate(response.body)
      else
        body = response.body
      end
    
      return body
    end
  end
end