require "test_helper"

class FuzzyDateFormTest < ActionDispatch::IntegrationTest
  def record_book(title, occurred_on)
    post books_path, params: { subject: { title: }, event: { type: "did", occurred_on: } }
    Subject.find_by(title:)&.events&.sole
  end

  test "日付は1つの欄で、最初は「今日」が入っている (数字ではなく言葉。開いたまま日付をまたいでも正しい)" do
    get new_book_path
    assert_select "input[type=text][name='event[occurred_on]'][value='今日']"
    assert_select "input[name='event[occurred_year]']", 0
  end

  test "「今日」のまま記録すると、記録した日 (日本時間) になる" do
    travel_to Time.utc(2026, 9, 24, 16, 30) do # 日本時間 9/25 1:30
      assert_equal "2026-09-25", record_book("細雪", "今日").occurred_on
    end
  end

  test "欄の横に今日・昨日・不明のボタンがある" do
    get new_book_path
    %w[今日 昨日 不明].each { |label| assert_select ".fuzzy-date button[type=button]", label }
  end

  test "書いた日付を精度に応じて記録する" do
    travel_to Date.new(2026, 9, 25) do
      assert_equal "2019", record_book("細雪", "2019").occurred_on
      assert_equal "2019-05", record_book("陰翳礼讃", "2019年5月").occurred_on
      assert_equal "2019-05-03", record_book("痴人の愛", "2019/5/3").occurred_on
      assert_equal "2026-09-24", record_book("鍵", "昨日").occurred_on
    end
  end

  test "時刻も書ける (分まで)。一覧に時刻も出る" do
    travel_to Date.new(2026, 9, 25) do
      assert_equal "2026-09-25T14:30", record_book("細雪", "2026/9/25 14:30").occurred_on
      assert_equal "2026-09-24T09:05", record_book("鍵", "昨日 9:05").occurred_on
    end

    get root_path
    assert_select ".event time[datetime='2026-09-25T14:30']", "2026年9月25日 14:30"
  end

  test "空なら日付不明で記録でき、一覧に日付不明と出る" do
    assert_nil record_book("細雪", "").occurred_on

    get root_path
    assert_select ".event .unknown-date", "日付不明"
  end

  test "読めない・暦に無い日付は 422 で、書いたまま戻る" do
    [ "あした", "2026/2/30" ].each do |text|
      assert_no_difference "Event.count" do
        assert_nil record_book("細雪", text)
      end
      assert_response :unprocessable_entity
      assert_select ".errors", /のように書いてください/
      assert_select "input[name='event[occurred_on]'][value=?]", text
    end
  end

  test "読み取った結果を返す (入力中の表示用)" do
    travel_to Date.new(2026, 9, 25) do
      { "9/25" => "2026年9月25日", "去年" => "2025年", "" => "日付不明", "あした" => "読めない" }.each do |text, label|
        get fuzzy_date_path(text:)
        assert_response :success
        assert_equal label, response.body, text
      end
    end
  end
end
