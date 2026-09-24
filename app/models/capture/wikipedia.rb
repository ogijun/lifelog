# Wikipedia の記事。曖昧さ回避の括弧「(1983年の映画)」「(小説)」「(film)」で種類が明らかなときに当てる。
# 括弧が無くても作品名そのものが映画を名乗っていれば当てる。それ以外は中身を見ないと分からないので
# nil を返し、種類を選ばせる (中身での判定は Wikidata を使う外部 API 連携の側)。
module Capture
  module Wikipedia
    ARTICLE = %r{\Ahttps://(ja|en)(?:\.m)?\.wikipedia\.org/wiki/([^?#]+)}
    QUALIFIED = /\A(.+) \(([^()]+)\)\z/
    # 言語ごとに [種類, 括弧の中身]。映画の年は IMDb と同じ「作品名 (年)」の形に揃える。
    KINDS = {
      "ja" => [ [ "film", /\A(?:(\d{4})年の)?.*映画\z/ ], [ "book", /(?:小説|漫画|書籍|絵本|随筆)\z/ ] ],
      "en" => [ [ "film", /\A(?:(\d{4}) )?(?:.* )?film\z/ ], [ "book", /(?:\A| )(?:novel|novella|book|manga|short story)\z/ ] ]
    }.freeze
    # 作品名が映画を名乗っているもの。「映画〜」は空白を含む作品名に限り、映画館・映画秘宝などを除く。
    FILM_NAME = /\A劇場版|\A映画\S*\s+\S|\bthe movie\b|ザ・ムービー/i

    module_function

    def call(url:, title:)
      article = ARTICLE.match(url) or return
      lang, path = article.captures
      name = Capture.fallback_title(title)
      found = by_qualifier(lang, name) || by_name(name) or return
      kind, name = found

      Hit.new(kind:, subject: { title: name, url: "https://#{lang}.wikipedia.org/wiki/#{path}" })
    end

    def by_qualifier(lang, title)
      qualified = QUALIFIED.match(title) or return
      name, qualifier = qualified.captures

      KINDS.fetch(lang).each do |kind, pattern|
        m = pattern.match(qualifier) or next
        return [ kind, m[1] ? "#{name} (#{m[1]})" : name ]
      end
      nil
    end

    # 末尾の括弧は作品名ではないので見ない (「映画 (曖昧さ回避)」を当てないため)。
    def by_name(title) = ([ "film", title ] if FILM_NAME.match?(title.sub(/ \([^()]+\)\z/, "")))
  end
end
