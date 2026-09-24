require "test_helper"

class Capture::YoutubeTest < ActiveSupport::TestCase
  CANONICAL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

  def recognize(url, title = "細雪を読む - YouTube") = Capture::Youtube.call(url:, title:)

  test "動画ページは動画。名前から - YouTube を外し、URL を watch?v=<ID> にする" do
    hit = recognize("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL1&t=42s")
    assert_equal "video", hit.kind
    assert_equal({ title: "細雪を読む", url: CANONICAL }, hit.subject)
  end

  test "短縮 URL・ショート・モバイル版も同じ動画" do
    [ "https://youtu.be/dQw4w9WgXcQ?si=abc", "https://www.youtube.com/shorts/dQw4w9WgXcQ",
      "https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ" ].each do |url|
      assert_equal CANONICAL, recognize(url)&.subject&.dig(:url), url
    end
  end

  test "通知の件数が付いたタイトル「(3) 細雪を読む - YouTube」から件数を外す" do
    assert_equal "細雪を読む", recognize("https://youtu.be/dQw4w9WgXcQ", "(3) 細雪を読む - YouTube").subject[:title]
  end

  test "動画ページでなければ nil" do
    assert_nil recognize("https://www.youtube.com/@channel", "チャンネル - YouTube")
    assert_nil recognize("https://www.youtube.com/results?search_query=x", "x - YouTube")
    assert_nil recognize("https://evil.example/watch?v=dQw4w9WgXcQ")
  end
end
