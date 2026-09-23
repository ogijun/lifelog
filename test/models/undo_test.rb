require "test_helper"

class UndoTest < ActiveSupport::TestCase
  setup do
    @first = Recorder.start(subject: { kind: "book", title: "細雪" }, event: { type: "wished", occurred_on: Date.new(2026, 1, 1) })
  end

  test "登録から1時間以内なら取り消せる" do
    assert @first.undoable?(now: @first.created_at + 59.minutes)
    assert_not @first.undoable?(now: @first.created_at + 61.minutes)
  end

  test "唯一のイベントを取り消すと subject ごと消える" do
    assert Recorder.undo(@first)
    assert_not Subject.exists?(@first.subject_id)
  end

  test "ほかにイベントがあれば subject は残る" do
    appended = Recorder.append(@first.subject, type: "did", occurred_on: Date.new(2026, 3, 1))

    assert Recorder.undo(appended)
    assert_equal "wished", CurrentState.find(@first.subject_id).status
  end

  test "期限を過ぎたら何も消さない" do
    assert_no_difference [ "Event.count", "Subject.count" ] do
      assert_not Recorder.undo(@first, now: @first.created_at + 2.hours)
    end
  end
end
