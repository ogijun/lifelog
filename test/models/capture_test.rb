require "test_helper"

class CaptureTest < ActiveSupport::TestCase
  test "当たった認識器の結果を返す" do
    hit = Capture.recognize(url: "https://www.google.com/maps/place/%E5%89%B2%E7%83%B9/", title: "割烹 - Google マップ")
    assert_equal "place", hit.kind
  end

  test "どの認識器にも当たらなければ nil" do
    assert_nil Capture.recognize(url: "https://example.com/", title: "何かのページ")
  end

  test "ブックマークレットが送るリンクの JSON を読む。壊れたもの・http(s) でないものは捨て、300 件まで" do
    json = [ [ "https://www.amazon.co.jp/dp/4101005052", "細雪" ], [ "javascript:alert(1)", "x" ], [ 1, 2 ], "junk",
             [ "https://example.com/a", "a" * 500 ] ].to_json
    links = Capture.links_from(json)
    assert_equal [ "https://www.amazon.co.jp/dp/4101005052", "https://example.com/a" ], links.map(&:href)
    assert_equal 200, links.last.text.size

    assert_equal [], Capture.links_from("not json")
    assert_equal [], Capture.links_from(nil)
    assert_equal 300, Capture.links_from(Array.new(400) { |i| [ "https://example.com/#{i}", "" ] }.to_json).size
  end

  test "リンクのうち認識できるものを候補にする。順番を保ち、同じものは1つに" do
    links = Capture.links_from([ [ "https://example.com/about", "about" ],
                                 [ "https://www.amazon.co.jp/dp/4101005052/ref=x", "細雪 (新潮文庫)" ],
                                 [ "https://youtu.be/dQw4w9WgXcQ", "紹介動画" ],
                                 [ "https://www.amazon.co.jp/%E7%B4%B0%E9%9B%AA/dp/4101005052", "Amazon で見る" ] ].to_json)
    candidates = Capture.candidates(links)

    assert_equal [ [ "book", "細雪 (新潮文庫)" ], [ "video", "紹介動画" ] ], candidates.map { [ it.kind, it.subject[:title] ] }
    assert_equal "9784101005058", candidates.first.subject[:isbn]
  end

  test "行き先が短縮 URL (X の t.co など) でも、リンクの文字が URL ならそれで判定する" do
    links = Capture.links_from([ [ "https://t.co/xTpSKCcmAO", "https://amazon.co.jp/dp/4101005052" ],
                                 [ "https://t.co/abc", "amazon.co.jp/dp/4041022093" ],
                                 [ "https://t.co/def", "amazon.co.jp/dp/48144…" ] ].to_json)

    assert_equal [ "https://www.amazon.co.jp/dp/4101005052", "https://www.amazon.co.jp/dp/4041022093" ],
                 Capture.candidates(links).map { it.subject[:url] }
  end

  test "名前の取れない候補には、選んだ文字かページのタイトルにある最初の『』を名前にする" do
    links = Capture.links_from([ [ "https://t.co/x", "https://amazon.co.jp/dp/4101005052" ],
                                 [ "https://youtu.be/dQw4w9WgXcQ", "紹介動画" ] ].to_json)
    candidates = Capture.candidates(links, hint: "新刊『細雪 上巻』の情報を公開しました")

    assert_equal [ "細雪 上巻", "紹介動画" ], candidates.map { it.subject[:title] }
  end

  test "『』の中を取り出す" do
    assert_equal "細雪 上巻", Capture.bracketed("新刊『細雪 上巻』と『鍵』")
    assert_nil Capture.bracketed("括弧なし")
    assert_nil Capture.bracketed(nil)
  end

  test "種類を選ばせるときの名前からは Wikipedia の接尾辞を外す" do
    assert_equal "細雪", Capture.fallback_title("細雪 - Wikipedia")
    assert_equal "何かのページ", Capture.fallback_title("何かのページ")
  end

  test "種類を選ばせるときの名前からは Google 検索の接尾辞も外す" do
    assert_equal "細雪", Capture.fallback_title("細雪 - Google 検索")
    assert_equal "細雪", Capture.fallback_title("細雪 - Google Search")
  end
end
