# ブックマークレットから来た URL とページタイトルを、記録する種類とフォームに埋める値に変える。
# 認識器は (url:, title:) -> Hit | nil の純粋関数。サイトを足すときは recognizers に1つ足す。
# 判定をサーバ側に置くのは、ブックマークレットを入れ直さずに対応サイトを増やすため。
module Capture
  # subject は各フォームの subject パラメータと同じ形。そのまま new_<kind>_path に渡す。
  Hit = Data.define(:kind, :subject)
  # ブックマークレットが送るページ内のリンク (行き先と、リンクの文字)。
  Link = Data.define(:href, :text)
  MAX_LINKS = 300
  # Netflix の日本語タイトルなどに混ざるゼロ幅の文字。
  ZERO_WIDTH = /[\u200B-\u200D\u2060\uFEFF]/

  module_function

  # PrimeVideo は amazon.co.jp の /dp/ で本 (Amazon) と形が重なるので先に置く。
  def recognizers = [ GoogleMaps, GoogleSearch, Tabelog, PrimeVideo, Amazon, Imdb, Wikipedia, Kyounoryouri,
                      Youtube, Netflix, DisneyPlus ]

  def recognize(url:, title:)
    title = title.to_s.gsub(ZERO_WIDTH, "")
    recognizers.lazy.filter_map { |r| r.call(url:, title:) }.first
  end

  # ブックマークレットが送るリンクの JSON ([[href, text], ...]) を読む。
  # 利用者のブラウザから来る値なので、形の違うもの・http(s) でないものは黙って捨てる。
  def links_from(json)
    rows = JSON.parse(json.to_s)
    return [] unless rows.is_a?(Array)

    rows.filter_map { |href, text| Link.new(href:, text: text.to_s.first(200)) if href.is_a?(String) && HttpUrl.valid?(href) }
        .first(MAX_LINKS)
  rescue JSON::ParserError
    []
  end

  # ページ内のリンクのうち、認識器が分かるものを候補にする (LLM を使わないパターンマッチ)。
  # ブックマークレットが「選んだ範囲 → 本文 → その他」の順に送るので、その順を保つ。
  def candidates(links)
    links.filter_map { |link| recognize(url: link.href, title: link.text) }.uniq { it.subject[:url] }
  end

  # 種類を選ばせるときに引き継ぐ名前。サイト名の接尾辞だけ外す。
  def fallback_title(title) = title.sub(/ - (?:Wikipedia|Google 検索|Google Search)\z/, "")
end
