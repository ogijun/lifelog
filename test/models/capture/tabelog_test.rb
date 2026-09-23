require "test_helper"

class Capture::TabelogTest < ActiveSupport::TestCase
  def recognize(url, title) = Capture::Tabelog.call(url:, title:)

  test "店名とジャンルを取り、読みを外し、URL は店ページの正規形にする" do
    hit = recognize("https://tabelog.com/hyogo/A2803/A280301/28000001/dtlrvwlst/?sort=new",
                    "芦屋の割烹 （あしやのかっぽう） - 芦屋/割烹・小料理 | 食べログ")
    assert_equal "place", hit.kind
    assert_equal({ title: "芦屋の割烹", creator: "割烹・小料理", url: "https://tabelog.com/hyogo/A2803/A280301/28000001/" },
                 hit.subject)
  end

  test "読みが無い店名" do
    hit = recognize("https://s.tabelog.com/hyogo/A2803/A280301/28000001/", "元町の洋食屋 - 元町/洋食、ハンバーグ | 食べログ")
    assert_equal [ "元町の洋食屋", "洋食、ハンバーグ" ], hit.subject.values_at(:title, :creator)
  end

  test "店名に - があっても最後の - 駅/ジャンル だけを外す" do
    hit = recognize("https://tabelog.com/hyogo/A2803/A280301/28000001/", "Bar - Ashiya - 芦屋/バー | 食べログ")
    assert_equal [ "Bar - Ashiya", "バー" ], hit.subject.values_at(:title, :creator)
  end

  test "タイトルの形が崩れていたら末尾の | 食べログ だけ外す" do
    hit = recognize("https://tabelog.com/hyogo/A2803/A280301/28000001/", "芦屋の割烹 | 食べログ")
    assert_equal({ title: "芦屋の割烹", url: "https://tabelog.com/hyogo/A2803/A280301/28000001/" }, hit.subject)
  end

  test "店のページでなければ nil" do
    assert_nil recognize("https://tabelog.com/hyogo/A2803/rstLst/", "芦屋のランキング | 食べログ")
    assert_nil recognize("https://evil.example/hyogo/A2803/A280301/28000001/", "x | 食べログ")
  end
end
