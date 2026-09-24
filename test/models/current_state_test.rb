require "test_helper"

class CurrentStateTest < ActiveSupport::TestCase
  test "最新イベントの type が status になる" do
    s = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: s, type: "wished", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 3, 1))

    row = CurrentState.find(s.id)
    assert_equal "did", row.status
    assert_equal "2026-03-01", row.as_of
  end

  test "再読しても did が並ぶだけで status は変わらない" do
    s = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 6, 1))

    assert_equal "did", CurrentState.find(s.id).status
    assert_equal 2, s.events.count
  end

  def record(subject, type, occurred_on) = Event.create!(subject:, type:, occurred_on:)

  test "日付不明のイベントはいちばん古い扱い" do
    s = Subject.create!(kind: "book", title: "細雪")
    record(s, "wished", "2026-03")
    record(s, "did", nil)

    assert_equal [ "wished", "2026-03" ], CurrentState.find(s.id).attributes.values_at("status", "as_of")
  end

  test "年だけ・月だけの日付はその期間の初め" do
    s = Subject.create!(kind: "book", title: "細雪")
    record(s, "wished", "2026-03-05")
    record(s, "did", "2026")

    assert_equal "wished", CurrentState.find(s.id).status
  end

  test "同じ日付どうしは記録順で後のものが最新" do
    s = Subject.create!(kind: "book", title: "細雪")
    10.times do |i|
      record(s, "wished", "2026")
      record(s, "did", "2026")
      assert_equal "did", CurrentState.find(s.id).status, "#{i} 回目"
      record(s, "wished", nil)
      record(s, "dropped", nil)
    end
  end

  test "イベントの無い subject は現れない" do
    s = Subject.create!(kind: "film", title: "細雪")
    assert_nil CurrentState.find_by(id: s.id)
  end

  test "読み取り専用" do
    s = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: s, type: "wished", occurred_on: Date.new(2026, 1, 1))

    assert_raises(ActiveRecord::ReadOnlyRecord) { CurrentState.find(s.id).update!(title: "x") }
  end
end
