require "test_helper"

class Capture::ImdbTest < ActiveSupport::TestCase
  def recognize(url, title) = Capture::Imdb.call(url:, title:)

  test "作品名 (年) を取り、URL は作品ページの正規形にする" do
    hit = recognize("https://www.imdb.com/ja/title/tt0085824/?ref_=nv_sr_srsg_0", "細雪 (1983) - IMDb")
    assert_equal "film", hit.kind
    assert_equal({ title: "細雪 (1983)", url: "https://www.imdb.com/title/tt0085824/" }, hit.subject)
  end

  test "評価とジャンルが付いた新しい形式のタイトル" do
    hit = recognize("https://m.imdb.com/title/tt0085824/", "The Makioka Sisters (1983) ⭐ 7.4 | Drama")
    assert_equal "The Makioka Sisters (1983)", hit.subject[:title]
  end

  test "作品ページでなければ nil" do
    assert_nil recognize("https://www.imdb.com/name/nm0411174/", "Kon Ichikawa - IMDb")
    assert_nil recognize("https://evil.example/title/tt0085824/", "x - IMDb")
  end
end
