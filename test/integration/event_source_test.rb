require "test_helper"

class EventSourceTest < ActionDispatch::IntegrationTest
  BLOG = "https://blog.example.com/posts/1".freeze

  test "5つの記録フォームに出どころの欄があり、URL のパラメータで埋まる" do
    [ new_book_path, new_film_path, new_dish_path, new_place_path, new_video_path ].each do |path|
      get path, params: { source_url: BLOG }
      assert_select "input[type=url][name='event[source_url]'][value=?]", BLOG, 1, path
    end
  end

  test "出どころ付きで記録すると、イベントの行にリンクで出る" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "wished", occurred_on: "2026", source_url: BLOG } }
    subject = Subject.find_by!(title: "細雪")
    assert_equal BLOG, subject.events.sole.source_url

    get subject_path(subject)
    assert_select ".event .source a[href=?][rel~=noreferrer]", BLOG
  end

  test "詳細ページの記録と、イベントの編集でも出どころを入れられる" do
    subject = Subject.create!(kind: "book", title: "細雪")
    event = Event.create!(subject:, type: "wished", occurred_on: "2026")

    post subject_events_path(subject), params: { event: { type: "did", occurred_on: "2026/9/1", source_url: BLOG } }
    assert_equal BLOG, subject.events.find_by!(type: "did").source_url

    get edit_event_path(event)
    assert_select "input[name='event[source_url]']"
    patch event_path(event), params: { event: { occurred_on: "2026", source_url: BLOG } }
    assert_equal BLOG, event.reload.source_url
  end

  test "http(s) でない出どころは 422" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "wished", occurred_on: "2026", source_url: "javascript:alert(1)" } }
    assert_response :unprocessable_entity
  end
end
