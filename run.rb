require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'typhoeus'
  #gem 'pry'
  gem 'nokogiri'
  gem 'builder'
end

require 'date'
require 'uri'

url = "https://steadyhq.com/de/realitatsabzweig/posts"
response = Typhoeus.get(url)
doc = Nokogiri::HTML(response.body)

posts = doc.search('article').map do |article|
  {
    title: article.search('h2').text,
    content: article.search('.post_teaser__body').text,
    url: URI.join(url, article.search('a[href]').first['href']).to_s,
    pubdate: Date.parse(article.search('.post_teaser__date').text),
    image: article.search('.post_teaser__image').first['style'].match(/url\((.*)\)/)[1].gsub(/['"]/, '')
  }
end


xml = Builder::XmlMarkup.new
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.rss :version => "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom", "xmlns:content" => "http://purl.org/rss/1.0/modules/content/", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.channel do
    xml.title "Steady Realitätsabzweig"
    xml.description "auto generated rss feed bridge"
    xml.link url

    posts.each do |post|
      xml.item do
        xml.title post[:title]
        xml.description post[:content]
        xml.link post[:url]
        xml.pubDate post[:pubdate].rfc822
        xml.guid post[:url]
        if post[:image]
          xml.enclosure :url => post[:image], :type => "image/jpeg"
          xml.media :content, :url => post[:image], :medium => "image", :type => "image/jpeg"
          xml.image do
            xml.url post[:image]
            xml
          end
        end
      end
    end
  end
end

File.write("output/rss.xml", xml.target!)
