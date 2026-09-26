require "test_helper"

class EventEditTest < ActionDispatch::IntegrationTest
  setup do
    @subject = Subject.create!(kind: "book", title: "細雪")
    @wished = Event.create!(subject: @subject, type: "wished", occurred_on: "2026-03")
    @did = Event.create!(subject: @subject, type: "did", occurred_on: "2019", rating: 3)
  end

  def edit(event, **fields)
    patch event_path(event), params: { event: { occurred_on: "", **fields } }
  end

  test "編集ページには今の日付・評価・メモが入っている" do
    get edit_event_path(@did)
    assert_response :success
    assert_select "input[name='event[occurred_on]'][value='2019']"
    assert_select "select[name='event[rating]'] option[selected][value='3']"
  end

  test "日付を直すと状態が計算し直され、詳細ページに戻る" do
    assert_equal "wished", CurrentState.find(@subject.id).status

    edit(@did, occurred_on: "2026/9/1")
    assert_redirected_to @subject
    assert_equal "2026-09-01", @did.reload.occurred_on
    assert_equal "did", CurrentState.find(@subject.id).status
  end

  test "評価とメモも直せ、日付を空にすれば不明になる" do
    edit(@did, rating: "5", note: "再読した")
    assert_equal [ nil, 5, "再読した" ], @did.reload.attributes.values_at("occurred_on", "rating", "note")
  end

  test "種別は送っても変わらない" do
    edit(@did, type: "dropped", occurred_on: "2019")
    assert_equal "did", @did.reload.type
  end

  test "暦に無い日付は 422 で編集ページに戻る" do
    edit(@did, occurred_on: "2019/2/30")
    assert_response :unprocessable_entity
    assert_select ".errors", /のように書いてください/
    assert_equal "2019", @did.reload.occurred_on
  end

  test "一覧の各イベントに編集へのリンクがある" do
    get subject_path(@subject)
    assert_select "a[href=?]", edit_event_path(@did)
  end
end
