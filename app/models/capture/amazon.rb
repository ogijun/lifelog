# Amazon の本の商品ページ。紙の本の ASIN は ISBN-10 そのものなので ISBN-13 に直す。
# 本以外の商品は nil を返し、何として記録するかを選ばせる。
module Capture
  module Amazon
    PRODUCT = %r{\Ahttps://(?:www\.)?amazon\.(co\.jp|com)/(?:[^?#]*/)?(?:dp|gp/product)/([A-Z0-9]{10})(?![A-Z0-9])}
    ISBN10 = /\A\d{9}[\dX]\z/
    BOOK_CATEGORIES = %w[本 Kindleストア].freeze
    # 「Amazon.co.jp: 書名 : 著者 : カテゴリ」。書名側にコロンがあり得るので右から切る。
    JP_PREFIX = /\AAmazon\.co\.jp\s*[:：]\s*/
    SEPARATOR = /\s*:\s*/

    module_function

    def call(url:, title:)
      product = PRODUCT.match(url) or return
      tld, asin = product.captures
      isbn = isbn13(asin) if ISBN10.match?(asin)
      name, creator, category = split_title(title)
      return unless isbn || BOOK_CATEGORIES.include?(category)

      Hit.new(kind: "book",
              subject: { title: name, creator:, isbn:, url: "https://www.amazon.#{tld}/dp/#{asin}" }.compact_blank)
    end

    # 形が崩れていたらタイトル全体を書名にする。
    def split_title(title)
      return [ title ] unless JP_PREFIX.match?(title)

      # 正規表現の rpartition は区切りの左側の空白を残すので strip する。
      rest, _, category = title.sub(JP_PREFIX, "").rpartition(SEPARATOR).map(&:strip)
      name, _, creator = rest.rpartition(SEPARATOR).map(&:strip)
      return [ title, nil, category ] if name.empty?

      [ name.delete_suffix(" eBook"), creator, category ]
    end

    def isbn13(isbn10)
      digits = "978#{isbn10[0, 9]}"
      sum = digits.chars.each_with_index.sum { |d, i| d.to_i * (i.even? ? 1 : 3) }
      "#{digits}#{(10 - sum % 10) % 10}"
    end
  end
end
