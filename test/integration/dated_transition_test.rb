require "test_helper"

class DatedTransitionTest < ActionDispatch::IntegrationTest
  setup do
    @book = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: @book, type: "wished", occurred_on: "2026-01")
  end

  def press(type, occurred_on, **event) = post(subject_transition_path(@book), params: { type:, event: { occurred_on:, **event } })

  test "ふだんはボタンだけ。細かく入れる欄 (日付・評価・メモ) は閉じた開閉の中にある" do
    get subject_path(@book)

    assert_select ".state form[action=?]", subject_transition_path(@book) do
      assert_select "button[name=type][value=did]", "読んだ"
      assert_select "button[name=type][value=dropped]", "やめた"
      assert_select "details:not([open]) summary", "日付や評価も入れる"
      assert_select "details input[type=text][name='event[occurred_on]'][value='今日']"
      assert_select "details .stars input[type=radio][name='event[rating]']", 5
      assert_select "details textarea[name='event[note]']"
    end
    assert_select "form.record", 0
  end

  test "評価とメモも同じボタンで一緒に記録できる" do
    press("did", "2019年", rating: "5", note: "学生のころ")

    event = @book.events.find_by!(type: "did")
    assert_equal [ "2019", 5, "学生のころ" ], event.attributes.values_at("occurred_on", "rating", "note")
  end

  test "閉じたまま押したとき (今日・評価なし・メモなし) は、今日で記録するだけ" do
    travel_to Date.new(2026, 9, 25) do
      press("did", "今日", rating: "", note: "")
    end

    event = @book.events.find_by!(type: "did")
    assert_equal [ "2026-09-25", nil, nil ], event.attributes.values_at("occurred_on", "rating", "note")
  end

  test "「今日」のまま押すと、押した日 (日本時間) で記録する" do
    travel_to Time.utc(2026, 9, 24, 16, 0) do # 日本時間 9/25 1:00
      press("did", "今日")
    end

    assert_redirected_to @book
    assert_equal "2026-09-25", @book.events.find_by!(type: "did").occurred_on
  end

  test "日付を書き換えて同じボタンを押すと、その日付で記録する。空にすれば不明" do
    travel_to Date.new(2026, 9, 25) do
      press("did", "2019年")
      press("did", "昨日 14:30")
      press("did", "")
    end

    assert_equal [ "2019", "2026-09-24T14:30", nil ].to_set, @book.events.where(type: "did").pluck(:occurred_on).to_set
  end

  test "読めない日付は記録せず、エラーを出す" do
    assert_no_difference "Event.count" do
      press("did", "あした")
    end
    assert_redirected_to @book
    follow_redirect!
    assert_select ".alert", /のように書いてください/
  end

  test "今日の候補の行は、日付の欄なしのボタンだけ (今日で記録)" do
    get wishlist_path
    assert_select ".event form[action=?]", subject_transition_path(@book) do
      assert_select "button[name=type][value=did]"
      assert_select "input[name='event[occurred_on]']", 0
    end

    travel_to Date.new(2026, 9, 25) do
      post subject_transition_path(@book), params: { type: "did" }
    end
    assert_equal "2026-09-25", @book.events.find_by!(type: "did").occurred_on
  end
end
