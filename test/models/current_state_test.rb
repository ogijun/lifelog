require "test_helper"

class CurrentStateTest < ActiveSupport::TestCase
  test "最新イベントの type が status になる" do
    s = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: s, type: "wished", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 3, 1))

    row = CurrentState.find(s.id)
    assert_equal "did", row.status
    assert_equal Date.new(2026, 3, 1), row.as_of
  end

  test "再読しても did が並ぶだけで status は変わらない" do
    s = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: s, type: "did", occurred_on: Date.new(2026, 6, 1))

    assert_equal "did", CurrentState.find(s.id).status
    assert_equal 2, s.events.count
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
