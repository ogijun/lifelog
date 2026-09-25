# Disney+ の作品ページ。タイトルは「〇〇を配信で見る | Disney+(ディズニープラス)」か「〇〇 | Watch on Disney+」。
module Capture
  module DisneyPlus
    ENTITY = %r{\A(https://www\.disneyplus\.com/(?:[a-z]{2}-[a-z]{2}/)?browse/entity-[0-9a-f-]{36})}

    module_function

    def call(url:, title:)
      entity = ENTITY.match(url) or return
      name = title.sub(/を配信で見る \| Disney\+.*\z/, "").sub(/ \| Watch on Disney\+\z/, "")
      Hit.new(kind: "video", subject: { title: name, url: entity[1] })
    end
  end
end
