require "test_helper"

class CoverFormTest < ActionDispatch::IntegrationTest
  PNG = Rails.root.join("test/fixtures/files/cover.png")
  EVENT = { type: "wished", occurred_year: "2026", occurred_month: "", occurred_day: "" }.freeze

  # 外部への通信の代わりに、決まった画像を返す。
  def with_remote_image
    original = RemoteImage.method(:fetch)
    RemoteImage.define_singleton_method(:fetch) do |_url, **|
      RemoteImage::Fetched.new(io: PNG.open, content_type: "image/png", filename: "cover.png")
    end
    yield
  ensure
    RemoteImage.define_singleton_method(:fetch, original)
  end

  test "5つのフォームに画像のファイル欄がある" do
    [ new_book_path, new_film_path, new_dish_path, new_place_path, new_video_path ].each do |path|
      get path
      assert_select "form[enctype='multipart/form-data'] input[type=file][name='subject[cover]']", 1, path
    end
  end

  test "ファイルを選んで記録すると対象に画像が付く" do
    post books_path, params: { subject: { title: "細雪", cover: fixture_file_upload("cover.png", "image/png") }, event: EVENT }
    assert Subject.find_by!(title: "細雪").cover.attached?
  end

  test "画像以外のファイルは 422 でフォームに戻る" do
    post books_path, params: { subject: { title: "細雪", cover: Rack::Test::UploadedFile.new(StringIO.new("text"), "text/plain", original_filename: "a.txt") }, event: EVENT }
    assert_response :unprocessable_entity
    assert_nil Subject.find_by(title: "細雪")
  end

  test "capture で来た画像はプレビューが出て、記録すると取り込む" do
    get new_video_path(subject: { title: "細雪を読む", image_url: "https://img.example.com/a.jpg" })
    assert_select "img[src='https://img.example.com/a.jpg']"
    assert_select "input[type=hidden][name='subject[image_url]'][value='https://img.example.com/a.jpg']"

    with_remote_image do
      post videos_path, params: { subject: { title: "細雪を読む", image_url: "https://img.example.com/a.jpg" }, event: EVENT }
    end
    assert Subject.find_by!(title: "細雪を読む").cover.attached?
  end

  test "ファイルと capture の画像が両方あればファイルを優先する" do
    fetched = false
    original = RemoteImage.method(:fetch)
    RemoteImage.define_singleton_method(:fetch) { |*, **| fetched = true; raise RemoteImage::Refused }
    post books_path, params: { subject: { title: "細雪", image_url: "https://img.example.com/a.jpg",
                                          cover: fixture_file_upload("cover.png", "image/png") }, event: EVENT }
    assert_not fetched
    assert Subject.find_by!(title: "細雪").cover.attached?
  ensure
    RemoteImage.define_singleton_method(:fetch, original)
  end

  test "画像が取れなくても記録はでき、取れなかったことだけ知らせる" do
    post books_path, params: { subject: { title: "細雪", image_url: "http://127.0.0.1/a.png" }, event: EVENT }

    subject = Subject.find_by!(title: "細雪")
    assert_not subject.cover.attached?
    follow_redirect!
    assert_select ".notice", /画像は取得できなかった/
  end

  test "http(s) でない画像の URL はプレビューも hidden も出さない" do
    get new_book_path(subject: { title: "細雪", image_url: "javascript:alert(1)" })
    assert_select "img", 0
    assert_select "input[name='subject[image_url]']", 0
  end
end
