require "test_helper"

class RecordingFlowTest < ActionDispatch::IntegrationTest
  test "4種類それぞれのフォームが独立して開く" do
    { new_book_path => "本を記録する", new_film_path => "映画を記録する",
      new_dish_path => "料理を記録する", new_place_path => "場所を記録する" }.each do |path, heading|
      get path
      assert_response :success
      assert_select "h2", heading
    end
  end

  test "場所のフォームにだけ緯度経度がある" do
    get new_place_path
    assert_select "input[name='subject[lat]']"

    get new_book_path
    assert_select "input[name='subject[lat]']", false
    assert_select "input[name='subject[isbn]']"
  end

  test "本を記録すると subject と event ができ詳細に飛ぶ" do
    assert_difference [ "Subject.count", "Event.count" ], 1 do
      post books_path, params: {
        subject: { title: "細雪", creator: "谷崎潤一郎", isbn: "9784101005058" },
        event: { type: "wished", occurred_on: "2026-01-01", note: "映画の前に" }
      }
    end

    subject = Subject.last
    assert_redirected_to subject
    assert_equal "9784101005058", subject.external_ids["isbn"]

    follow_redirect!
    assert_select "h2", /細雪/
    assert_select ".type-wished"
  end

  test "タイトルが空なら 422 でフォームに戻る" do
    assert_no_difference "Subject.count" do
      post books_path, params: { subject: { title: "" }, event: { type: "wished", occurred_on: "2026-01-01" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "詳細から追記すると状態が変わる" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "wished", occurred_on: "2026-01-01" } }
    subject = Subject.last

    post subject_events_path(subject), params: { event: { type: "did", occurred_on: "2026-03-01", rating: "5" } }
    assert_redirected_to subject

    assert_equal "did", CurrentState.find(subject.id).status
  end

  test "追記は Turbo Stream で一覧と状態を差し替える" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "wished", occurred_on: "2026-01-01" } }
    subject = Subject.last

    post subject_events_path(subject),
      params: { event: { type: "did", occurred_on: "2026-03-01" } },
      as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match %r{action="prepend" target="events"}, response.body
    assert_match %r{action="update" target="state"}, response.body
  end

  test "caused_by で連鎖が辿れる" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "did", occurred_on: "2026-01-01" } }
    read = Event.last

    post films_path, params: {
      subject: { title: "細雪 (1983)", creator: "市川崑" },
      event: { type: "wished", occurred_on: "2026-01-05", caused_by: read.id }
    }

    assert_equal read, Event.last.cause
    get root_path
    assert_select ".cause", /細雪 から/
  end
end

class ListingTest < ActionDispatch::IntegrationTest
  test "時系列は kind をまたいで一本に並び kind で絞れる" do
    post books_path, params: { subject: { title: "細雪" }, event: { type: "did", occurred_on: "2026-01-01" } }
    post places_path, params: { subject: { title: "蘆屋" }, event: { type: "did", occurred_on: "2026-05-01" } }

    get root_path
    assert_response :success
    assert_select ".event", 2

    get root_path(kind: "book")
    assert_select ".event", 1
    assert_select ".event", /細雪/
  end

  test "今日の候補には wished だけが出る" do
    post books_path, params: { subject: { title: "したい本" }, event: { type: "wished", occurred_on: "2026-01-01" } }
    post films_path, params: { subject: { title: "観た映画" }, event: { type: "did", occurred_on: "2026-01-01" } }

    get wishlist_path
    assert_response :success
    assert_select ".event", 1
    assert_select ".event", /したい本/
  end
end
