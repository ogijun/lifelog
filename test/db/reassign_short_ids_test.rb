require "test_helper"
require Rails.root.join("db/migrate/20260925000002_reassign_short_ids")

class ReassignShortIdsTest < ActiveSupport::TestCase
  UUIDS = { book: "11111111-1111-4111-8111-111111111111", film: "22222222-2222-4222-8222-222222222222",
            read: "33333333-3333-4333-8333-333333333333", watch: "44444444-4444-4444-8444-444444444444" }.freeze

  setup do
    now = Time.current
    Subject.insert_all!([ { id: UUIDS[:book], kind: "book", title: "細雪", created_at: now },
                          { id: UUIDS[:film], kind: "film", title: "細雪 (1983)", created_at: now } ])
    Event.insert_all!([ { id: UUIDS[:read], subject_id: UUIDS[:book], type: "did", occurred_on: "2026", caused_by: nil, created_at: now },
                        { id: UUIDS[:watch], subject_id: UUIDS[:film], type: "did", occurred_on: nil,
                          caused_by: UUIDS[:read], created_at: now } ])
    @short = Subject.create!(kind: "dish", title: "既に短い")

    ActiveRecord::Migration.suppress_messages { ReassignShortIds.new.up }
  end

  test "UUID の ID は短い ID に振り直され、参照はつながったまま" do
    book = Subject.find_by!(title: "細雪")
    film = Subject.find_by!(title: "細雪 (1983)")
    read = book.events.sole
    watch = film.events.sole

    [ book, film, read, watch ].each { |r| assert_match ShortId::FORMAT, r.id }
    assert_equal read, watch.cause
    assert_empty ActiveRecord::Base.connection.select_rows("PRAGMA foreign_key_check")
  end

  test "既に短い ID の行は変えない" do
    assert Subject.exists?(@short.id)
  end

  test "元の UUID はどこにも残らない" do
    ids = Subject.pluck(:id) + Event.pluck(:id, :subject_id, :caused_by).flatten
    assert_empty ids & UUIDS.values
  end
end
