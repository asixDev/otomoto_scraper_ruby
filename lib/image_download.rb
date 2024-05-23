# frozen_string_literal: true

require "down"

module OtomotoImageDownloader
  def self.download(url, car_id)
    url.sub!(/\d+x\d+$/, "0x600")
    tempimg = Down.download(url, extension: "png")
    File.open("output/images/#{car_id}.png", "wb") do |img|
      img.write tempimg.read
    end
    tempimg.unlink
  end
end
