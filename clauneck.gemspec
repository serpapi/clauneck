Gem::Specification.new do |s|
  s.name = 'clauneck'
  s.version = '0.0.1'
  s.date = '2023-07-05'
  s.summary = "Custom Lead Acquisition Using Next-Generation Extraction and Collection Kit"
  s.description = "A tool for scraping emails, social media accounts, and many more information from websites using Google Search Results."
  s.authors = ["Emirhan Akdeniz"]
  s.email = 'kagermanovtalks@gmail.com'
  s.files = ["lib/clauneck.rb", "bin/clauneck"]
  s.homepage = 'https://github.com/serpapi/clauneck'
  s.license = 'MIT'
  s.require_paths = ["lib"]
  s.bindir = 'bin'
  s.executables = ["clauneck"]
  s.add_dependency 'faraday', '~> 2.7', '>= 2.7.9'
  s.add_dependency 'json', '~> 2.6', '>= 2.6.3'
  s.add_dependency 'optparse', '~> 0.3.1'
  s.add_dependency 'concurrent-ruby', '~> 1.2', '>= 1.2.2'
  s.add_dependency 'csv', '~> 3.2', '>= 3.2.7'
  s.add_dependency 'zlib', '~> 3.0'
  s.add_dependency 'stringio', '~> 3.0', '>= 3.0.7'
  s.add_dependency 'brotli', '~> 0.4.0'
end
