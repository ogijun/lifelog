# ブックマークレットから来た URL とページタイトルを、記録する種類とフォームに埋める値に変える。
# 認識器は (url:, title:) -> Hit | nil の純粋関数。サイトを足すときは recognizers に1つ足す。
# 判定をサーバ側に置くのは、ブックマークレットを入れ直さずに対応サイトを増やすため。
module Capture
  # subject は各フォームの subject パラメータと同じ形。そのまま new_<kind>_path に渡す。
  Hit = Data.define(:kind, :subject)
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

  # 種類を選ばせるときに引き継ぐ名前。サイト名の接尾辞だけ外す。
  def fallback_title(title) = title.sub(/ - (?:Wikipedia|Google 検索|Google Search)\z/, "")
end
