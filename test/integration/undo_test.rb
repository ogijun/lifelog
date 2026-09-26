require "test_helper"

class UndoFlowTest < ActionDispatch::IntegrationTest
  setup do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "wished", occurred_on: "2026/1/1" } }
    @subject = Subject.find_by!(title: "細雪")
    @event = @subject.events.sole
  end

  test "期限内は取り消しボタンが出て、押すと消えて時系列に戻る" do
    get root_path
    assert_select "form[action=?] button", event_path(@event), text: "取り消す"

    delete event_path(@event)
    assert_redirected_to root_path
    assert_not Subject.exists?(@subject.id)
  end

  test "追記を取り消したら詳細ページに戻る" do
    post subject_events_path(@subject), params: { event: { type: "did", occurred_on: "2026/3/1" } }
    appended = @subject.events.find_by!(type: "did")

    delete event_path(appended)
    assert_redirected_to @subject
    assert_equal [ @event ], @subject.events.reload.to_a
  end

  test "期限を過ぎたらボタンは出ず、送っても消えない" do
    travel 2.hours do
      get root_path
      assert_select "form[action=?]", event_path(@event), false

      assert_no_difference "Event.count" do
        delete event_path(@event)
      end
      assert_redirected_to @subject
      follow_redirect!
      assert_select ".alert", /取り消せない/
    end
  end
end
