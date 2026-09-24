require "test_helper"

class FuzzyDateFormTest < ActionDispatch::IntegrationTest
  def record_book(title, year:, month: "", day: "")
    post books_path, params: {
      subject: { title: },
      event: { type: "did", occurred_year: year, occurred_month: month, occurred_day: day }
    }
    Subject.find_by(title:)&.events&.sole
  end

  test "フォームには今日の年・月・日が入っている" do
    travel_to Date.new(2026, 9, 25) do
      get new_book_path
      assert_select "input[name='event[occurred_year]'][value='2026']"
      assert_select "input[name='event[occurred_month]'][value='9']"
      assert_select "input[name='event[occurred_day]'][value='25']"
    end
  end

  test "年だけ・年と月だけでも記録できる" do
    assert_equal "2019", record_book("細雪", year: "2019").occurred_on
    assert_equal "2019-05", record_book("陰翳礼讃", year: "2019", month: "5").occurred_on
    assert_equal "2019-05-03", record_book("痴人の愛", year: "2019", month: "5", day: "3").occurred_on
  end

  test "全部空なら日付不明で記録でき、一覧に日付不明と出る" do
    assert_nil record_book("細雪", year: "").occurred_on

    get root_path
    assert_select ".event .unknown-date", "日付不明"
  end

  test "暦に無い日付は 422 でフォームに戻る" do
    assert_no_difference "Event.count" do
      assert_nil record_book("細雪", year: "2026", month: "2", day: "30")
    end
    assert_response :unprocessable_entity
    assert_select ".errors", /暦にある日付/
  end

  test "詳細ページの追記も年・月・日で送れる" do
    subject = record_book("細雪", year: "2019").subject
    post subject_events_path(subject), params: { event: { type: "wished", occurred_year: "2026", occurred_month: "", occurred_day: "" } }

    assert_equal [ "2019", "2026" ], subject.events.order(:created_at).pluck(:occurred_on)
  end
end
