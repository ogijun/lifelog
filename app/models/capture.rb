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
  # 名前の取れなかった候補には、hint (選んだ文字やページのタイトル) にある最初の『』を名前にする。
  def candidates(links, hint: nil)
    name = bracketed(hint)
    links.filter_map { recognize_link(it) }.uniq { it.subject[:url] }.map do |hit|
      hit.subject[:title].present? || name.nil? ? hit : hit.with(subject: hit.subject.merge(title: name))
    end
  end

  # 行き先で分からなければ、リンクの文字が URL ならそれで判定する。
  # X は投稿のリンクを t.co に置き換え、リンクの文字に元の URL を出すため。
  def recognize_link(link)
    recognize(url: link.href, title: link.text) || (url = url_in_text(link.text)) && recognize(url:, title: "")
  end

  # リンクの文字が URL そのものなら、その URL。「https://」の省かれた「amazon.co.jp/dp/…」も補う。
  # 途中で切られた (「…」付きの) ものや、ドメインらしくないものは使わない。
  def url_in_text(text)
    text = text.to_s.strip
    return if text.include?("…") || text.match?(/\s/)

    url = text.match?(%r{\Ahttps?://}) ? text : "https://#{text}"
    url if HttpUrl.valid?(url) && URI(url).host.include?(".")
  end

  # 日本語の書名は『』で囲まれることが多い。最初の『』の中身。
  def bracketed(text) = text.to_s[/『([^』]+)』/, 1]

  # 種類を選ばせるときに引き継ぐ名前。サイト名の接尾辞だけ外す。
  def fallback_title(title) = title.sub(/ - (?:Wikipedia|Google 検索|Google Search)\z/, "")
end
