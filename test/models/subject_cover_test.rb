require "test_helper"

class SubjectCoverTest < ActiveSupport::TestCase
  PNG = Rails.root.join("test/fixtures/files/cover.png")

  test "対象に画像を1枚付けられ、文字列の ID でも読み戻せる" do
    s = Subject.create!(kind: "book", title: "細雪")
    s.cover.attach(io: PNG.open, filename: "cover.png", content_type: "image/png")

    assert Subject.find(s.id).cover.attached?
    assert_equal "cover.png", Subject.find(s.id).cover.filename.to_s
  end

  test "画像以外は付けられない" do
    s = Subject.create!(kind: "book", title: "細雪")
    s.cover.attach(io: StringIO.new("not an image"), filename: "x.txt", content_type: "text/plain")

    assert_not s.valid?
    assert_includes s.errors[:cover], "は画像にしてください"
  end
end
