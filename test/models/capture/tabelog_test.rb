require "test_helper"

class Capture::TabelogTest < ActiveSupport::TestCase
  def recognize(url, title) = Capture::Tabelog.call(url:, title:)

  test "店名とジャンルを取り、URL は店ページの正規形にする" do
    hit = recognize("https://tabelog.com/hyogo/A2803/A280301/28000001/dtlrvwlst/?sort=new",
                    "芦屋の割烹 (芦屋/割烹・小料理) - 食べログ")
    assert_equal "place", hit.kind
    assert_equal({ title: "芦屋の割烹", creator: "割烹・小料理", url: "https://tabelog.com/hyogo/A2803/A280301/28000001/" },
                 hit.subject)
  end

  test "店名に括弧があっても最後の (駅/ジャンル) だけを外す" do
    hit = recognize("https://s.tabelog.com/hyogo/A2803/A280301/28000001/", "洋食屋 (旧店名) (元町、三宮/洋食) - 食べログ")
    assert_equal [ "洋食屋 (旧店名)", "洋食" ], hit.subject.values_at(:title, :creator)
  end

  test "タイトルの形が崩れていたら末尾の - 食べログ だけ外す" do
    hit = recognize("https://tabelog.com/hyogo/A2803/A280301/28000001/", "芦屋の割烹 - 食べログ")
    assert_equal({ title: "芦屋の割烹", url: "https://tabelog.com/hyogo/A2803/A280301/28000001/" }, hit.subject)
  end

  test "店のページでなければ nil" do
    assert_nil recognize("https://tabelog.com/hyogo/A2803/rstLst/", "芦屋のランキング - 食べログ")
    assert_nil recognize("https://evil.example/hyogo/A2803/A280301/28000001/", "x - 食べログ")
  end
end
