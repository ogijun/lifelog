# Netflix の作品ページ。タイトルは「〇〇を観る | Netflix (ネットフリックス) 公式サイト」か
# 「Watch 〇〇 | Netflix Official Site」。日本語版に混ざるゼロ幅の文字は Capture.recognize で外してある。
module Capture
  module Netflix
    TITLE_PAGE = %r{\Ahttps://www\.netflix\.com/(?:[a-z]{2}(?:-[a-z]{2})?/)?title/(\d+)}

    module_function

    def call(url:, title:)
      page = TITLE_PAGE.match(url) or return
      name = title.sub(/\s*を観る \| Netflix.*\z/, "").sub(/\AWatch /, "").sub(/ \| Netflix.*\z/, "")
      Hit.new(kind: "video", subject: { title: name, url: "https://www.netflix.com/title/#{page[1]}" })
    end
  end
end
