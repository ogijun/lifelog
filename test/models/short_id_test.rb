require "test_helper"

class ShortIdTest < ActiveSupport::TestCase
  test "11 文字の base58 (見間違えやすい 0 O I l と記号を含まない)" do
    100.times { assert_match ShortId::FORMAT, ShortId.generate }
    assert_no_match ShortId::FORMAT, "0OIl0OIl0OI"
  end

  test "毎回ちがう" do
    assert_equal 1000, Array.new(1000) { ShortId.generate }.uniq.size
  end

  test "subject と event は短い ID で採番される" do
    s = Subject.create!(kind: "book", title: "細雪")
    e = Event.create!(subject: s, type: "did", occurred_on: "2026")
    assert_match ShortId::FORMAT, s.id
    assert_match ShortId::FORMAT, e.id
  end
end
