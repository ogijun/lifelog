# 食べログの店ページ。タイトルは「店名 （読み） - 駅/ジャンル | 食べログ」。
module Capture
  module Tabelog
    SHOP = %r{\Ahttps://(?:s\.)?tabelog\.com/([a-z]+/A\d+/A\d+/\d+)/}
    SUFFIX = " | 食べログ".freeze
    READING = /\s*（[^（）]*）\z/

    module_function

    def call(url:, title:)
      shop = SHOP.match(url) or return
      name, genre = parse_title(title.delete_suffix(SUFFIX))
      Hit.new(kind: "place", subject: { title: name, creator: genre, url: "https://tabelog.com/#{shop[1]}/" }.compact_blank)
    end

    # 店名側にも " - " があり得るので、最後の " - " の右を「駅/ジャンル」とみなす。
    def parse_title(title)
      name, _, area = title.rpartition(" - ")
      return [ title ] unless area.include?("/")

      [ name.sub(READING, ""), area.split("/", 2).last ]
    end
  end
end
