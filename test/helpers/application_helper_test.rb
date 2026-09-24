require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "述語は種類ごとに変わる" do
    assert_equal "読みたい", type_label("wished", "book")
    assert_equal "観た", type_label("did", "film")
    assert_equal "作りたい", type_label("wished", "dish")
    assert_equal "行った", type_label("did", "place")
  end

  test "やめた は種類によらない" do
    assert_equal "やめた", type_label("dropped", "book")
  end

  test "日付は精度に応じて表示し、機械向けの datetime も付ける" do
    assert_dom_equal '<time datetime="2026-03">2026年3月</time>', fuzzy_date_tag("2026-03")
    assert_dom_equal '<span class="unknown-date">日付不明</span>', fuzzy_date_tag(nil)
  end

  test "したいと思ってからの期間は、日付の精度に合わせて言う" do
    travel_to Date.new(2026, 9, 25) do
      assert_equal "about 1 month 前から", wished_since("2026-08-20")
      assert_equal "2026年3月から", wished_since("2026-03")
      assert_equal "2025年から", wished_since("2025")
      assert_equal "いつからか分からない", wished_since(nil)
    end
  end

  test "未知の種類は汎用の述語に落ちる" do
    assert_equal "したい", type_label("wished", "album")
  end
end
