require "test_helper"

class Capture::AmazonTest < ActiveSupport::TestCase
  def recognize(url, title) = Capture::Amazon.call(url:, title:)

  test "紙の本は ASIN を ISBN-13 にし、タイトルを書名と著者に分ける" do
    hit = recognize("https://www.amazon.co.jp/%E7%B4%B0%E9%9B%AA/dp/4101005052/ref=sr_1_1?keywords=x",
                    "Amazon.co.jp: 細雪 (新潮文庫) : 谷崎 潤一郎 : 本")
    assert_equal "book", hit.kind
    assert_equal({ title: "細雪 (新潮文庫)", creator: "谷崎 潤一郎", isbn: "9784101005058",
                   url: "https://www.amazon.co.jp/dp/4101005052" }, hit.subject)
  end

  test "チェックディジットが X の ISBN-10" do
    hit = recognize("https://www.amazon.co.jp/dp/404102209X", "Amazon.co.jp: x : y : 本")
    assert_equal "9784041022092", hit.subject[:isbn]
  end

  test "Kindle 版は ISBN なしで書名から eBook を外す" do
    hit = recognize("https://www.amazon.co.jp/gp/product/B00ABCDEFG",
                    "Amazon.co.jp: 細雪 eBook : 谷崎 潤一郎: Kindleストア")
    assert_equal({ title: "細雪", creator: "谷崎 潤一郎", url: "https://www.amazon.co.jp/dp/B00ABCDEFG" }, hit.subject)
  end

  test "書名にコロンがあっても崩れない" do
    hit = recognize("https://www.amazon.co.jp/dp/4101005052", "Amazon.co.jp: 陰翳礼讃: 随筆集 : 谷崎 潤一郎 : 本")
    assert_equal [ "陰翳礼讃: 随筆集", "谷崎 潤一郎" ], hit.subject.values_at(:title, :creator)
  end

  test "タイトルの形が崩れていても ISBN があれば本として全体を書名に入れる" do
    hit = recognize("https://www.amazon.com/dp/0679761640", "The Makioka Sisters")
    assert_equal({ title: "The Makioka Sisters", isbn: "9780679761648", url: "https://www.amazon.com/dp/0679761640" },
                 hit.subject)
  end

  test "本以外の商品は nil (種類を選ばせる)" do
    assert_nil recognize("https://www.amazon.co.jp/dp/B0XXXXXXXX", "Amazon.co.jp: 土鍋 9号 : ホーム&キッチン")
  end

  test "Amazon の商品ページでなければ nil" do
    assert_nil recognize("https://www.amazon.co.jp/s?k=%E7%B4%B0%E9%9B%AA", "Amazon.co.jp : 細雪")
    assert_nil recognize("https://evil.example/dp/4101005052", "x : y : 本")
  end
end
