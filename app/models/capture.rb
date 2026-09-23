# ブックマークレットから来た URL とページタイトルを、記録する種類とフォームに埋める値に変える。
# 認識器は (url:, title:) -> Hit | nil の純粋関数。サイトを足すときは recognizers に1つ足す。
# 判定をサーバ側に置くのは、ブックマークレットを入れ直さずに対応サイトを増やすため。
module Capture
  # subject は各フォームの subject パラメータと同じ形。そのまま new_<kind>_path に渡す。
  Hit = Data.define(:kind, :subject)

  module_function

  def recognizers = [ GoogleMaps, Tabelog, Amazon, Imdb ]

  def recognize(url:, title:)
    recognizers.lazy.filter_map { |r| r.call(url:, title:) }.first
  end
end
