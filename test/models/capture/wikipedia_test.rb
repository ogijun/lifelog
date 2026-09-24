require "test_helper"

class Capture::WikipediaTest < ActiveSupport::TestCase
  JA = "https://ja.wikipedia.org/wiki/%E7%B4%B0%E9%9B%AA_(1983%E5%B9%B4%E3%81%AE%E6%98%A0%E7%94%BB)"

  def recognize(url, title) = Capture::Wikipedia.call(url:, title:)

  test "「(1983年の映画)」は映画で、名前を「細雪 (1983)」にする" do
    hit = recognize("#{JA}?oldid=1", "細雪 (1983年の映画) - Wikipedia")
    assert_equal "film", hit.kind
    assert_equal({ title: "細雪 (1983)", url: JA }, hit.subject)
  end

  test "年の無い「(映画)」は名前だけ" do
    assert_equal "細雪", recognize(JA, "細雪 (映画) - Wikipedia").subject[:title]
  end

  test "小説・漫画・書籍は本" do
    [ "細雪 (小説)", "細雪 (谷崎潤一郎の小説)", "細雪 (漫画)", "細雪 (書籍)" ].each do |title|
      hit = recognize(JA, "#{title} - Wikipedia")
      assert_equal [ "book", "細雪" ], [ hit.kind, hit.subject[:title] ], title
    end
  end

  test "英語版の film / novel" do
    url = "https://en.m.wikipedia.org/wiki/The_Makioka_Sisters_(1983_film)"
    film = recognize(url, "The Makioka Sisters (1983 film) - Wikipedia")
    assert_equal [ "film", "The Makioka Sisters (1983)" ], [ film.kind, film.subject[:title] ]
    assert_equal "https://en.wikipedia.org/wiki/The_Makioka_Sisters_(1983_film)", film.subject[:url]

    assert_equal "film", recognize(url, "The Makioka Sisters (Japanese film) - Wikipedia").kind
    assert_equal "book", recognize(url, "The Makioka Sisters (novel) - Wikipedia").kind
  end

  test "括弧が無くても作品名が明らかに映画なら映画" do
    [ "機動警察パトレイバー 2 the Movie", "映画ドラえもん のび太の恐竜", "劇場版 細雪", "細雪 ザ・ムービー" ].each do |title|
      hit = recognize(JA, "#{title} - Wikipedia")
      assert_equal [ "film", title ], [ hit&.kind, hit&.subject&.dig(:title) ], title
    end
    assert_equal "film", recognize("https://en.wikipedia.org/wiki/Patlabor_2:_The_Movie", "Patlabor 2: The Movie - Wikipedia").kind
  end

  test "映画についての記事は映画作品として当てない" do
    [ "映画館", "映画秘宝", "映画の日", "映画監督", "Movie theater" ].each do |title|
      assert_nil recognize(JA, "#{title} - Wikipedia"), title
    end
  end

  test "括弧が無い、または種類が分からない括弧なら nil (種類を選ばせる)" do
    assert_nil recognize(JA, "細雪 - Wikipedia")
    assert_nil recognize(JA, "細雪 (テレビドラマ) - Wikipedia")
    assert_nil recognize(JA, "芦屋 (兵庫県) - Wikipedia")
    assert_nil recognize(JA, "映画 (曖昧さ回避) - Wikipedia")
  end

  test "Wikipedia の記事でなければ nil" do
    assert_nil recognize("https://evil.example/wiki/x", "細雪 (小説) - Wikipedia")
  end
end
