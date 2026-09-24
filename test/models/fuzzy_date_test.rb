require "test_helper"

class FuzzyDateTest < ActiveSupport::TestCase
  test "フォームの年・月・日から精度に応じた文字列を組む" do
    assert_equal "2026-03-05", FuzzyDate.from_parts(year: "2026", month: "3", day: "5")
    assert_equal "2026-03", FuzzyDate.from_parts(year: "2026", month: "3", day: "")
    assert_equal "2026", FuzzyDate.from_parts(year: " 2026 ", month: "", day: "")
  end

  test "粗い欄が空なら細かい欄は無視し、年が空なら不明 (nil)" do
    assert_equal "2026", FuzzyDate.from_parts(year: "2026", month: "", day: "5")
    assert_nil FuzzyDate.from_parts(year: "", month: "3", day: "5")
    assert_nil FuzzyDate.from_parts(year: nil, month: nil, day: nil)
  end

  test "数字でない入力は組んだまま返し、判定はバリデーションに任せる" do
    assert_equal "20x6", FuzzyDate.from_parts(year: "20x6", month: "", day: "")
    assert_not FuzzyDate.valid?("20x6")
  end

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

  test "Date からは日の精度" do
    assert_equal "2026-03-05", FuzzyDate.from_date(Date.new(2026, 3, 5))
  end
end
