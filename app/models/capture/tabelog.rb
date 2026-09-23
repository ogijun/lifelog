# 食べログの店ページ。タイトルは「店名 (駅/ジャンル) - 食べログ」。
module Capture
  module Tabelog
    SHOP = %r{\Ahttps://(?:s\.)?tabelog\.com/([a-z]+/A\d+/A\d+/\d+)/}
    # 店名側にも括弧があり得るので、最後の括弧を (駅/ジャンル) とみなす。
    TITLE = %r{\A(.+) \(([^()]*/[^()]*)\) - 食べログ\z}

    module_function

    def call(url:, title:)
      shop = SHOP.match(url) or return
      name, genre = parse_title(title)
      Hit.new(kind: "place", subject: { title: name, creator: genre, url: "https://tabelog.com/#{shop[1]}/" }.compact_blank)
    end

    def parse_title(title)
      m = TITLE.match(title) or return [ title.delete_suffix(" - 食べログ") ]
      [ m[1], m[2].split("/").last ]
    end
  end
end
