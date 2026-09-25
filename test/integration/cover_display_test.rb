require "test_helper"

class CoverDisplayTest < ActionDispatch::IntegrationTest
  PNG = Rails.root.join("test/fixtures/files/cover.png")

  setup do
    @subject = Subject.create!(kind: "book", title: "細雪")
    Event.create!(subject: @subject, type: "wished", occurred_on: "2026")
  end

  def attach_cover = @subject.cover.attach(io: PNG.open, filename: "cover.png", content_type: "image/png")

  test "画像があれば詳細・時系列・今日の候補に出る" do
    attach_cover

    get subject_path(@subject)
    assert_select "img.cover"
    get root_path
    assert_select ".event img.thumb"
    get wishlist_path
    assert_select ".event img.thumb"
  end

  test "画像が無ければ何も出さない" do
    get subject_path(@subject)
    assert_select "img.cover", 0
    get root_path
    assert_select "img.thumb", 0
  end

  test "詳細ページから画像を差し替えられる" do
    attach_cover
    old = @subject.cover.blob

    patch subject_cover_path(@subject), params: { cover: fixture_file_upload("cover.png", "image/png") }
    assert_redirected_to @subject
    assert_not_equal old, @subject.reload.cover.blob
  end

  test "画像以外では差し替えず、エラーを出す" do
    patch subject_cover_path(@subject), params: { cover: Rack::Test::UploadedFile.new(StringIO.new("text"), "text/plain", original_filename: "a.txt") }
    assert_redirected_to @subject
    follow_redirect!
    assert_select ".alert", /画像/
    assert_not @subject.reload.cover.attached?
  end

  test "詳細ページから画像を外せる" do
    attach_cover
    delete subject_cover_path(@subject)
    assert_redirected_to @subject
    assert_not @subject.reload.cover.attached?
  end
end
