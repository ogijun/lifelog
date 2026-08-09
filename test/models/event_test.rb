require "test_helper"

class EventTest < ActiveSupport::TestCase
  def subject!
    Subject.create!(kind: "book", title: "細雪", creator: "谷崎潤一郎")
  end

  test "type と occurred_on は追記のみで書き換えられない" do
    e = Event.create!(subject: subject!, type: "wished", occurred_on: Date.new(2026, 1, 1))

    e.type = "did"
    assert_not e.valid?
    assert_includes e.errors[:type], "は後から変更できません"

    e.reload.occurred_on = Date.new(2026, 2, 1)
    assert_not e.valid?
    assert_includes e.errors[:occurred_on], "は後から変更できません"
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
end
