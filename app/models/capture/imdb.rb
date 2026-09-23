# IMDb の作品ページ。タイトルは「作品名 (年) - IMDb」か「作品名 (年) ⭐ 7.4 | Drama」。
module Capture
  module Imdb
    TITLE_PAGE = %r{\Ahttps://(?:www\.|m\.)?imdb\.com/(?:[a-z]{2}/)?title/(tt\d+)}

    module_function

    def call(url:, title:)
      page = TITLE_PAGE.match(url) or return
      name = title.sub(/\s*-\s*IMDb\z/, "").sub(/\s*⭐.*\z/, "")
      Hit.new(kind: "film", subject: { title: name, url: "https://www.imdb.com/title/#{page[1]}/" }.compact_blank)
    end
  end
end
