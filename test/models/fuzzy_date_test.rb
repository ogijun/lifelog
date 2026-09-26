require "test_helper"

class FuzzyDateTest < ActiveSupport::TestCase
  test "形式と暦の正しさ" do
    [ nil, "2026", "2026-12", "2024-02-29" ].each { |s| assert FuzzyDate.valid?(s), s.inspect }
    [ "", "26", "2026-13", "2026-00", "2026-02-30", "2025-02-29", "2026-3-5", "2026-03-05T10:00" ].each do |s|
      assert_not FuzzyDate.valid?(s), s.inspect
    end
  end

  test "精度に応じた表示" do
    assert_equal "2026年3月5日", FuzzyDate.label("2026-03-05")
    assert_equal "2026年3月", FuzzyDate.label("2026-03")
    assert_equal "2026年", FuzzyDate.label("2026")
    assert_equal "日付不明", FuzzyDate.label(nil)
  end

  test "フォームに戻すための年・月・日" do
    assert_equal({ year: "2026", month: "3", day: "5" }, FuzzyDate.parts("2026-03-05"))
    assert_equal({ year: "2026", month: nil, day: nil }, FuzzyDate.parts("2026"))
    assert_equal({ year: nil, month: nil, day: nil }, FuzzyDate.parts(nil))
  end

  TODAY = Date.new(2026, 9, 25)

  def parse(text) = FuzzyDate.parse(text, today: TODAY)

  test "書いた日付を精度に応じて読み取る" do
    { "2026/9/25" => "2026-09-25", "2026-09-25" => "2026-09-25", "2026.9.25" => "2026-09-25",
      "2026年9月25日" => "2026-09-25", "20260925" => "2026-09-25", " 2026/9/25 " => "2026-09-25",
      "2026/9" => "2026-09", "2026-9" => "2026-09", "2026年9月" => "2026-09",
      "2026" => "2026", "2026年" => "2026" }.each do |text, expected|
      assert_equal expected, parse(text), text
    end
  end

  test "年を省くと今年" do
    assert_equal "2026-03-05", parse("3/5")
    assert_equal "2026-03-05", parse("3月5日")
  end

  test "全角の数字や記号も読む" do
    assert_equal "2026-09-25", parse("２０２６／９／２５")
  end

  test "よく使う言葉" do
    { "今日" => "2026-09-25", "昨日" => "2026-09-24", "一昨日" => "2026-09-23", "おととい" => "2026-09-23",
      "今月" => "2026-09", "先月" => "2026-08", "今年" => "2026", "去年" => "2025", "昨年" => "2025" }.each do |text, expected|
      assert_equal expected, parse(text), text
    end
    assert_equal "2025-12", FuzzyDate.parse("先月", today: Date.new(2026, 1, 10))
  end

  test "空は不明" do
    assert_nil parse("")
    assert_nil parse("  ")
    assert_nil parse(nil)
  end

  test "読めないものは書いたまま返し、判定はバリデーションに任せる" do
    assert_equal "あした", parse("あした")
    assert_not FuzzyDate.valid?(parse("あした"))
    assert_not FuzzyDate.valid?(parse("2026/2/30"))
  end

  test "入力欄には人が読みやすい形で戻す" do
    assert_equal "2026/9/5", FuzzyDate.input_value("2026-09-05")
    assert_equal "2026/9", FuzzyDate.input_value("2026-09")
    assert_equal "2026", FuzzyDate.input_value("2026")
    assert_equal "", FuzzyDate.input_value(nil)
    assert_equal "あした", FuzzyDate.input_value("あした")
  end

  test "Date からは日の精度" do
    assert_equal "2026-03-05", FuzzyDate.from_date(Date.new(2026, 3, 5))
  end
end
