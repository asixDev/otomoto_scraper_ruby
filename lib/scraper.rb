# frozen_string_literal: true

require "tanakai"
require "fileutils"
require_relative "image_download"
require_relative "pdf_builder"

class OtomotoScraper < Tanakai::Base
  @engine = :selenium_chrome
  @start_urls = ["https://www.otomoto.pl/osobowe/gmc?page=1"]

  def self.open_spider
    Dir.mkdir("output") unless Dir.exist?("output")
    FileUtils.rm_rf("output/.", secure: true)
    Dir.mkdir("output/images")
  end

  def parse(response, url:, data: {})
    if response.at_xpath("//article/h1[text()='Brak wyników wyszukiwania']")
      raise StandardError,
            "No #{url[/[a-z]+\?/][0..-2]} cars"
    else
      car_articles = response.xpath("//div[@data-testid='search-results']/div/article")
      car_articles.each do |car_article|
        img_tag = car_article.at_xpath("section/div/img") || car_article.at_xpath("section//div[@data-testid='carousel-container']//img")
        request_to :parse_car, url: car_article.at_xpath("section/div/h1/a").attr("href"),
                               data: { image: img_tag.at_xpath("@src").value }
      end
      more_pages_attr = response.at_xpath("//ul[contains(@class, 'pagination-list')]/li[@title='Next Page']/@aria-disabled")
      request_to :parse, url: url.succ unless more_pages_attr.nil? || more_pages_attr.value == "true"
    end
  end

  def parse_car(response, url:, data: {})
    car = {}
    car[:id] = url.scan(/-\w+\./)[0][1..-2]
    car[:name] =
      response.at_xpath("//main/div/section/div[@data-testid='summary-info-area']/div/h3[contains(@class, 'offer-title')]/text()").text
    price_container = response.at_xpath("//main/div/section/div[@data-testid='summary-info-area']//p[contains(@class, 'offer-price__currency')]/..")
    car[:price] =
      "#{price_container.at_xpath("*[contains(@class, 'offer-price__number')]/text()").text} #{price_container.at_xpath("*[contains(@class, 'offer-price__currency')]/text()").text}"
    details = response.xpath("//div[@data-testid='content-details-section']/div/div[@data-testid='advert-details-item']")
    detail_map = {
      production: "Rok produkcji",
      mileage: "Przebieg",
      fuel: "Rodzaj paliwa",
      horsepower: "Moc",
      color: "Kolor",
      wear: "Stan"
    }
    detail_map.each do |key, value|
      car[key] = details.at_xpath("p[text()='#{value}']/../*[text()!='#{value}']/text()").text
    end
    OtomotoImageDownloader.download(data[:image], car[:id])
    save_to "output/scraped_cars.csv", car, format: :csv, position: false
  end

  def self.close_spider
    OtomotoPdfBuilder.build(File.open("output/scraped_cars.csv", "r"))
  end
end

OtomotoScraper.crawl!
