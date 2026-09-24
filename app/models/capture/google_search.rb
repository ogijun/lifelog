# Google 検索のナレッジパネル。Google マップの共有リンク (share.google) はここに展開される。
# 英語 UI だとマップの店ページは英語名になるが、共有リンクの q には現地名が入っている。
module Capture
  module GoogleSearch
    SEARCH = %r{\Ahttps://(?:www\.)?google\.[a-z.]+/search\?}
    # 共有元が場所であることの印 (source=sh/x/loc/...)。
    LOCATION = %r{/loc/}
    # 末尾のかなだけの括弧は読み。「(本店)」のようなものは残す。
    READING = /\s*[（(][\p{Hiragana}\p{Katakana}ー・]+[）)]\z/

    module_function

    def call(url:, title:)
      return unless SEARCH.match?(url)

      query = URI.decode_www_form(URI(url).query).to_h
      kgmid, name = query.values_at("kgmid", "q")
      return unless kgmid && name.present? && LOCATION.match?(query["source"].to_s)

      Hit.new(kind: "place", subject: { title: name.sub(READING, ""),
                                        url: "https://www.google.com/search?#{URI.encode_www_form(kgmid:, q: name)}" })
    rescue URI::Error, ArgumentError
      nil
    end
  end
end
