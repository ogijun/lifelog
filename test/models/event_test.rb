require "test_helper"

class EventTest < ActiveSupport::TestCase
  def subject!
    Subject.create!(kind: "book", title: "細雪", creator: "谷崎潤一郎")
  end

  test "type は追記のみで書き換えられない" do
    e = Event.create!(subject: subject!, type: "wished", occurred_on: Date.new(2026, 1, 1))

    e.type = "did"
    assert_not e.valid?
    assert_includes e.errors[:type], "は後から変更できません"
  end

  test "occurred_on は後から直せる" do
    e = Event.create!(subject: subject!, type: "did", occurred_on: "2019")

    assert e.update(occurred_on: "2019-05-03")
    assert_equal "2019-05-03", e.reload.occurred_on
  end

  test "occurred_on は精度可変で、不明 (nil) も許す" do
    s = subject!
    [ nil, "2019", "2019-05", "2019-05-03", Date.new(2019, 5, 3) ].each do |occurred_on|
      assert Event.new(subject: s, type: "did", occurred_on:).valid?, occurred_on.inspect
    end
  end

  test "形式が違う・暦に無い occurred_on はエラー" do
    s = subject!
    [ "20x6", "2019-13", "2019-02-30", "2019/05/03" ].each do |occurred_on|
      e = Event.new(subject: s, type: "did", occurred_on:)
      assert_not e.valid?, occurred_on
      assert_includes e.errors[:occurred_on], "は「2019」「2019-05」「2019-05-03」の形の、暦にある日付にしてください"
    end
  end

  test "rating と note は普通に更新できる" do
    e = Event.create!(subject: subject!, type: "did", occurred_on: Date.new(2026, 1, 1))

    assert e.update(rating: 5, note: "再読")
    assert_equal 5, e.reload.rating
  end

  test "type は wished / did / dropped のみ" do
    e = Event.new(subject: subject!, type: "started", occurred_on: Date.new(2026, 1, 1))
    assert_not e.valid?
  end

  test "rating は 1-5" do
    s = subject!
    assert_not Event.new(subject: s, type: "did", occurred_on: Date.current, rating: 6).valid?
    assert Event.new(subject: s, type: "did", occurred_on: Date.current, rating: 1).valid?
  end

  test "STI は無効" do
    assert_predicate Event.inheritance_column, :blank?
  end

  test "caused_by で別のイベントを原因として辿れる" do
    read = Event.create!(subject: subject!, type: "did", occurred_on: Date.new(2026, 1, 1))
    film = Subject.create!(kind: "film", title: "細雪")
    watch = Event.create!(subject: film, type: "wished", occurred_on: Date.new(2026, 1, 5), cause: read)

    assert_equal read, watch.reload.cause
    assert_equal [ watch ], read.effects.to_a
  end

  test "フォームの「きっかけ: —」が送る空文字の caused_by は nil として保存される" do
    e = Event.create!(subject: subject!, type: "did", occurred_on: Date.new(2026, 1, 1), caused_by: "")
    assert_nil e.reload.caused_by
  end
end
