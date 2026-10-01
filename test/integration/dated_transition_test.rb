require "test_helper"

class DatedTransitionTest < ActionDispatch::IntegrationTest
  setup do
    @book = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: @book, type: "wished", occurred_on: "2026-01")
  end

  def record(**event) = post(subject_transition_path(@book), params: { event: { type: "did", occurred_on: "", **event } })

  test "詳細ページには、日付を指定して記録する画面へのリンクがある (フォームそのものは置かない)" do
    get subject_path(@book)
    assert_select ".state a[href=?]", new_subject_transition_path(@book), text: "日付や評価を指定して記録"
    assert_select "form.record", 0
  end

  test "指定の画面は、次の状態が選ばれていて、今日の日付が入っている" do
    travel_to Date.new(2026, 9, 25) do
      get new_subject_transition_path(@book)
    end

    assert_response :success
    assert_select "h2", /細雪/
    assert_select "fieldset.type-choice input[type=radio][value=did][checked]"
    assert_select "input[name='event[occurred_on]'][value='2026/9/25']"
    assert_select "select[name='event[rating]']"
    assert_select "input[name='event[source_url]']"
  end

  test "曖昧な日付・評価・メモを指定して記録できる" do
    record(occurred_on: "2019年", rating: "5", note: "学生のころ")

    assert_redirected_to @book
    event = @book.events.find_by!(type: "did")
    assert_equal [ "2019", 5, "学生のころ" ], event.attributes.values_at("occurred_on", "rating", "note")
  end

  test "日付を空にすれば不明、時刻も書ける" do
    record(occurred_on: "")
    record(occurred_on: "2026/9/25 14:30")

    assert_equal [ nil, "2026-09-25T14:30" ], @book.events.where(type: "did").order(:created_at).pluck(:occurred_on)
  end

  test "読めない日付は 422 で、書いたまま画面に戻る" do
    assert_no_difference "Event.count" do
      record(occurred_on: "あした")
    end
    assert_response :unprocessable_entity
    assert_select ".errors", /のように書いてください/
    assert_select "input[name='event[occurred_on]'][value='あした']"
  end

  test "ボタンのほう (指定なし) は今までどおり今日で記録する" do
    travel_to Date.new(2026, 9, 25) do
      post subject_transition_path(@book), params: { type: "did" }
    end
    assert_equal "2026-09-25", @book.events.find_by!(type: "did").occurred_on
  end
end
