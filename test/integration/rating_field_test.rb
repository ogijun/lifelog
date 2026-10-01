require "test_helper"

class RatingFieldTest < ActionDispatch::IntegrationTest
  test "評価は星5つと「なし」のラジオで、最初は「なし」が選ばれている" do
    [ new_book_path, new_film_path, new_dish_path, new_place_path, new_video_path ].each do |path|
      get path
      assert_select "fieldset.rating-input" do
        (1..5).each { |n| assert_select ".stars input[type=radio][name='event[rating]'][value='#{n}']", 1, "#{path} #{n}" }
        assert_select "input[type=radio][name='event[rating]'][value=''][checked]"
        assert_select ".stars label", 5
      end
      assert_select "select[name='event[rating]']", 0
    end
  end

  test "星のラジオとラベルは id で対になっていて、同じページに2つあってもぶつからない" do
    get new_book_path
    ids = css_select(".stars input").map { it["id"] }
    assert_equal ids, css_select(".stars label").map { it["for"] }
    assert_equal ids.uniq, ids
  end

  test "編集では今の評価が選ばれている" do
    subject = Subject.create!(kind: "book", title: "細雪")
    event = Event.create!(subject:, type: "did", occurred_on: "2026", rating: 3)

    get edit_event_path(event)
    assert_select ".stars input[type=radio][value='3'][checked]"
    assert_select "input[type=radio][name='event[rating]'][value=''][checked]", 0
  end

  test "「なし」を選んで直すと評価が消える" do
    subject = Subject.create!(kind: "book", title: "細雪")
    event = Event.create!(subject:, type: "did", occurred_on: "2026", rating: 3)

    patch event_path(event), params: { event: { occurred_on: "2026", rating: "" } }
    assert_nil event.reload.rating
  end
end
