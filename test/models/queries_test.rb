require "test_helper"

class RecorderTest < ActiveSupport::TestCase
  test "subject と最初のイベントを同時に作る" do
    event = Recorder.start(
      subject: { kind: "book", title: "細雪", creator: "谷崎潤一郎" },
      event: { type: "wished", occurred_on: Date.new(2026, 1, 1), note: "映画を観る前に" }
    )

    assert_equal "細雪", event.subject.title
    assert_equal "wished", event.type
    assert_equal "wished", CurrentState.find(event.subject_id).status
  end

  test "subject が不正なら event も残らない" do
    assert_no_difference [ "Subject.count", "Event.count" ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        Recorder.start(subject: { kind: "album", title: "x" }, event: { type: "wished", occurred_on: Date.current })
      end
    end
  end

  test "既存 subject に追記する" do
    e = Recorder.start(subject: { kind: "book", title: "細雪" }, event: { type: "wished", occurred_on: Date.new(2026, 1, 1) })
    Recorder.append(e.subject, type: "did", occurred_on: Date.new(2026, 3, 1), rating: 5)

    assert_equal "did", CurrentState.find(e.subject_id).status
  end
end

class TimelineTest < ActiveSupport::TestCase
  test "全 kind が occurred_on の降順で一本に並ぶ" do
    book = Subject.create!(kind: "book", title: "細雪")
    place = Subject.create!(kind: "place", title: "蘆屋")
    Event.create!(subject: book, type: "did", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: place, type: "did", occurred_on: Date.new(2026, 5, 1))

    assert_equal [ "蘆屋", "細雪" ], Timeline.recent.map { |e| e.subject.title }
  end

  test "kind で絞れる" do
    book = Subject.create!(kind: "book", title: "細雪")
    place = Subject.create!(kind: "place", title: "蘆屋")
    Event.create!(subject: book, type: "did", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: place, type: "did", occurred_on: Date.new(2026, 5, 1))

    assert_equal [ "細雪" ], Timeline.recent(kind: "book").map { |e| e.subject.title }
  end
end

class WishlistTest < ActiveSupport::TestCase
  def seed_wishes(n)
    n.times do |i|
      s = Subject.create!(kind: "book", title: "book-#{i}")
      Event.create!(subject: s, type: "wished", occurred_on: Date.new(2026, 1, 1) + i)
    end
  end

  test "wished のものだけを返す" do
    seed_wishes(3)
    done = Subject.create!(kind: "book", title: "done")
    Event.create!(subject: done, type: "wished", occurred_on: Date.new(2026, 1, 1))
    Event.create!(subject: done, type: "did", occurred_on: Date.new(2026, 2, 1))

    assert_not_includes Wishlist.suggestions(on: Date.new(2026, 6, 1), limit: 10).map(&:title), "done"
  end

  test "同じ日付なら並びは同じ、日付が変わると並びが変わる" do
    seed_wishes(12)
    a = Wishlist.suggestions(on: Date.new(2026, 6, 1)).map(&:id)
    b = Wishlist.suggestions(on: Date.new(2026, 6, 1)).map(&:id)
    c = Wishlist.suggestions(on: Date.new(2026, 6, 2)).map(&:id)

    assert_equal a, b
    assert_not_equal a, c
  end

  test "limit の件数だけ返す" do
    seed_wishes(12)
    assert_equal 5, Wishlist.suggestions(on: Date.new(2026, 6, 1), limit: 5).size
  end
end
