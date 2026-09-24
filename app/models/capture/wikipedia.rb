# Wikipedia の記事。曖昧さ回避の括弧「(1983年の映画)」「(小説)」「(film)」で種類が明らかなときだけ当てる。
# 括弧が無い記事は中身を見ないと分からないので nil を返し、種類を選ばせる。
module Capture
  module Wikipedia
    ARTICLE = %r{\Ahttps://(ja|en)(?:\.m)?\.wikipedia\.org/wiki/([^?#]+)}
    QUALIFIED = /\A(.+) \(([^()]+)\)\z/
    # 言語ごとに [種類, 括弧の中身]。映画の年は IMDb と同じ「作品名 (年)」の形に揃える。
    KINDS = {
      "ja" => [ [ "film", /\A(?:(\d{4})年の)?.*映画\z/ ], [ "book", /(?:小説|漫画|書籍|絵本|随筆)\z/ ] ],
      "en" => [ [ "film", /\A(?:(\d{4}) )?(?:.* )?film\z/ ], [ "book", /(?:\A| )(?:novel|novella|book|manga|short story)\z/ ] ]
    }.freeze

    module_function

    def call(url:, title:)
      article = ARTICLE.match(url) or return
      lang, path = article.captures
      qualified = QUALIFIED.match(Capture.fallback_title(title)) or return
      name, qualifier = qualified.captures

      KINDS.fetch(lang).each do |kind, pattern|
        m = pattern.match(qualifier) or next
        name = "#{name} (#{m[1]})" if m[1]
        return Hit.new(kind:, subject: { title: name, url: "https://#{lang}.wikipedia.org/wiki/#{path}" })
      end
      nil
    end
  end
end
