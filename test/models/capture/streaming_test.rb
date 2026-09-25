require "test_helper"

# 形式は 2026-09 に実物で確認した (amazon.co.jp の Prime Video だけは取得を拒否されて未確認)。作品名は架空。
class Capture::StreamingTest < ActiveSupport::TestCase
  def recognize(url, title) = Capture.recognize(url:, title:)

  test "Netflix: 作品ページは動画。日英のタイトルから作品名を取り、URL を /title/<id> にする" do
    ja = recognize("https://www.netflix.com/jp/title/80000001?s=i&trkid=1", "細雪を観る | Netflix (ネットフリックス) 公式サイト")
    en = recognize("https://www.netflix.com/title/80000001", "Watch The Makioka Sisters | Netflix Official Site")

    assert_equal [ "video", "細雪", "https://www.netflix.com/title/80000001" ], [ ja.kind, *ja.subject.values_at(:title, :url) ]
    assert_equal "The Makioka Sisters", en.subject[:title]
  end

  test "Netflix の日本語タイトルに混ざるゼロ幅の文字を取り除く" do
    title = "細雪\u{FEFF}を観\u{FEFF}る | Netflix (\u{FEFF}ネ\u{FEFF}ッ\u{FEFF}ト\u{FEFF}フ\u{FEFF}リ\u{FEFF}ッ\u{FEFF}ク\u{FEFF}ス\u{FEFF}) 公\u{FEFF}式サ\u{FEFF}イ\u{FEFF}ト"
    assert_equal "細雪", recognize("https://www.netflix.com/jp/title/80000001", title).subject[:title]
  end

  test "Prime Video: primevideo.com の作品ページ" do
    hit = recognize("https://www.primevideo.com/-/ja/detail/0ABCDEFGHIJ/ref=atv_dp?autoplay=0", "Prime Video: 細雪 シーズン１")
    assert_equal [ "video", "細雪 シーズン１", "https://www.primevideo.com/detail/0ABCDEFGHIJ/" ],
                 [ hit.kind, *hit.subject.values_at(:title, :url) ]
  end

  test "Prime Video: amazon.co.jp の作品ページ (本の認識器より先に当てる)" do
    detail = recognize("https://www.amazon.co.jp/gp/video/detail/B0ABCDEFGH/ref=x", "Amazon.co.jp: 細雪を観る | Prime Video")
    dp = recognize("https://www.amazon.co.jp/%E7%B4%B0%E9%9B%AA/dp/B0ABCDEFGH", "Amazon.co.jp: 細雪を観る | Prime Video")

    assert_equal [ "video", "細雪", "https://www.amazon.co.jp/gp/video/detail/B0ABCDEFGH/" ],
                 [ detail.kind, *detail.subject.values_at(:title, :url) ]
    assert_equal detail, dp
  end

  test "Disney+: 作品ページは動画。日英のタイトルから作品名を取る" do
    url = "https://www.disneyplus.com/ja-jp/browse/entity-11111111-2222-3333-4444-555555555555"
    ja = recognize("#{url}?distributionPartner=x", "細雪を配信で見る | Disney+(ディズニープラス)")
    en = recognize(url.sub("ja-jp", "en-us"), "The Makioka Sisters | Watch on Disney+")

    assert_equal [ "video", "細雪", url ], [ ja.kind, *ja.subject.values_at(:title, :url) ]
    assert_equal "The Makioka Sisters", en.subject[:title]
  end

  test "作品ページでなければ当てない" do
    assert_nil recognize("https://www.netflix.com/browse", "Netflix")
    assert_nil recognize("https://www.primevideo.com/storefront/", "Prime Video")
    assert_nil recognize("https://www.disneyplus.com/ja-jp/home", "Disney+")
    assert_equal "book", recognize("https://www.amazon.co.jp/dp/4101005052", "Amazon.co.jp: 細雪 : 谷崎 潤一郎 : 本").kind
  end
end
