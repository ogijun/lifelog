require "test_helper"

class StateTransitionTest < ActionDispatch::IntegrationTest
  setup do
    @video = Subject.create!(kind: "video", title: "細雪を読む")
    Event.create!(subject: @video, type: "wished", occurred_on: "2026-09")
  end

  def status = CurrentState.find(@video.id).status

  test "見たいのときは、詳細ページの状態の横に「見た」「やめた」のボタンが出る" do
    get subject_path(@video)
    assert_select ".state form[action=?] button", subject_transition_path(@video), text: "見た"
    assert_select ".state form[action=?] button", subject_transition_path(@video), text: "やめた"
  end

  test "見たのときは「また見たい」と「もう一度見た」、やめたのときは「見たい」が出る" do
    Event.create!(subject: @video, type: "did", occurred_on: "2026-09-10")
    get subject_path(@video)
    assert_select ".state button", text: "また見たい"
    assert_select ".state button", text: "もう一度見た"

    Event.create!(subject: @video, type: "dropped", occurred_on: "2026-09-11")
    get subject_path(@video)
    assert_select ".state button", text: "見たい"
  end

  test "ボタンを押すと、押した日 (日本時間) の日付で記録して詳細ページに戻る" do
    travel_to Time.utc(2026, 9, 24, 16, 0) do # 日本時間 9/25 1:00
      post subject_transition_path(@video), params: { type: "did" }
    end

    assert_redirected_to @video
    assert_equal "did", status
    assert_equal "2026-09-25", @video.events.find_by!(type: "did").occurred_on
  end

  test "「もう一度見た」は、見たをもう1件記録する (再読・再訪)" do
    Event.create!(subject: @video, type: "did", occurred_on: "2026-09-10")

    travel_to Date.new(2026, 9, 25) do
      post subject_transition_path(@video), params: { type: "did" }
    end

    assert_equal [ "2026-09-10", "2026-09-25" ], @video.events.where(type: "did").order(:occurred_on).pluck(:occurred_on)
    assert_equal "did", status
  end

  test "今日の候補の各行にも次の状態のボタンがある" do
    get wishlist_path
    assert_select ".event form[action=?] button", subject_transition_path(@video), text: "見た"
  end

  test "知らない状態は記録せず、エラーを出す" do
    assert_no_difference "Event.count" do
      post subject_transition_path(@video), params: { type: "started" }
    end
    assert_redirected_to @video
    follow_redirect!
    assert_select ".alert"
  end
end
