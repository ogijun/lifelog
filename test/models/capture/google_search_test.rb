require "test_helper"

class Capture::GoogleSearchTest < ActiveSupport::TestCase
  # share.google の共有リンクが展開される先の形 (2026-09 に確認)。店名は架空。
  def share_url(q, source: "sh/x/loc/uni/m1/1")
    "https://www.google.com/search?client=safari&rls=en&sxsrf=AB:1&kgmid=/g/1abc&" +
      URI.encode_www_form(q:, source:) + "&utm_source=x"
  end

  def recognize(url, title = "Google Search") = Capture::GoogleSearch.call(url:, title:)

  test "場所の共有リンクは店。英語 UI でも q の現地名を店名にし、かなの読みを外す" do
    hit = recognize(share_url("喫茶 猫屋敷(ねこやしき)"))
    assert_equal "place", hit.kind
    assert_equal({ title: "喫茶 猫屋敷",
                   url: "https://www.google.com/search?kgmid=%2Fg%2F1abc&q=%E5%96%AB%E8%8C%B6+%E7%8C%AB%E5%B1%8B%E6%95%B7%28%E3%81%AD%E3%81%93%E3%82%84%E3%81%97%E3%81%8D%29" },
                 hit.subject)
  end

  test "読みでない括弧は残す" do
    assert_equal "喫茶 猫屋敷 (本店)", recognize(share_url("喫茶 猫屋敷 (本店)")).subject[:title]
  end

  test "場所以外の共有や普通の検索は nil (種類を選ばせる)" do
    assert_nil recognize(share_url("細雪", source: "sh/x/kp/m1/1"))
    assert_nil recognize("https://www.google.com/search?q=%E7%B4%B0%E9%9B%AA")
    assert_nil recognize("https://evil.example/search?kgmid=/g/1&q=x&source=sh/x/loc/")
  end
end
