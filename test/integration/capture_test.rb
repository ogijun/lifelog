require "test_helper"

class CaptureFlowTest < ActionDispatch::IntegrationTest
  MAPS_URL = "https://www.google.com/maps/place/%E8%8A%A6%E5%B1%8B%E3%81%AE%E5%89%B2%E7%83%B9/" \
             "@34.72,135.30,17z/data=!3m1!4b1!8m2!3d34.7275!4d135.305"

  test "認識できたら値を埋めたその種類のフォームへ飛ぶ" do
    get capture_path(url: MAPS_URL, title: "芦屋の割烹 - Google マップ")

    assert_redirected_to new_place_path(subject: { title: "芦屋の割烹", lat: "34.7275", lng: "135.305", url: MAPS_URL })
    follow_redirect!
    assert_select "input[name='subject[title]'][value=?]", "芦屋の割烹"
    assert_select "input[name='subject[lat]'][value=?]", "34.7275"
    assert_select "input[name='subject[url]'][value=?]", MAPS_URL
  end

  test "認識できなければ種類を選ばせ、タイトルと URL を引き継ぐ" do
    get capture_path(url: "https://example.com/x", title: "何かのページ")

    assert_response :success
    assert_select "a[href=?]", new_book_path(subject: { title: "何かのページ", url: "https://example.com/x" })
    assert_select "a[href=?]", new_film_path(subject: { title: "何かのページ", url: "https://example.com/x" })
    assert_select "a[href=?]", new_dish_path(subject: { title: "何かのページ", recipe_url: "https://example.com/x" })
    assert_select "a[href=?]", new_place_path(subject: { title: "何かのページ", url: "https://example.com/x" })
    assert_select "a[href=?]", new_video_path(subject: { title: "何かのページ", url: "https://example.com/x" })
  end

  test "括弧の無い Wikipedia 記事は種類を選ばせ、名前から接尾辞を外す" do
    url = "https://ja.wikipedia.org/wiki/%E7%B4%B0%E9%9B%AA"
    get capture_path(url:, title: "細雪 - Wikipedia")

    assert_response :success
    assert_select "a[href=?]", new_book_path(subject: { title: "細雪", url: })
  end

  test "5つのフォームはどれも subject パラメータで値が埋まる" do
    get new_book_path(subject: { title: "細雪", creator: "谷崎潤一郎", isbn: "9784101005058", url: "https://example.com/b" })
    assert_select "input[name='subject[isbn]'][value=?]", "9784101005058"
    assert_select "input[name='subject[url]'][value=?]", "https://example.com/b"

    get new_film_path(subject: { title: "細雪 (1983)", url: "https://example.com/f" })
    assert_select "input[name='subject[title]'][value=?]", "細雪 (1983)"
    assert_select "input[name='subject[url]'][value=?]", "https://example.com/f"

    get new_dish_path(subject: { title: "鯛の子の煮付け", recipe_url: "https://example.com/d" })
    assert_select "input[name='subject[recipe_url]'][value=?]", "https://example.com/d"

    get new_video_path(subject: { title: "細雪を読む", creator: "読書チャンネル", url: "https://example.com/v" })
    assert_select "input[name='subject[creator]'][value=?]", "読書チャンネル"
    assert_select "input[name='subject[url]'][value=?]", "https://example.com/v"

    get new_place_path(subject: { title: "芦屋の割烹" })
    assert_select "input[name='subject[title]'][value=?]", "芦屋の割烹"
  end

  test "埋めるだけで保存はしない" do
    assert_no_difference "Subject.count" do
      get capture_path(url: MAPS_URL)
      follow_redirect!
    end
  end

  test "記録すると元 URL が external_ids に入る" do
    post books_path, params: {
      subject: { title: "細雪", url: "https://example.com/b" },
      event: { type: "wished", occurred_year: "2026", occurred_month: "1", occurred_day: "1" }
    }

    assert_equal "https://example.com/b", Subject.find_by!(title: "細雪").external_ids["url"]
  end

  test "ブックマークレットは /capture に URL とタイトルを送る" do
    get bookmarklet_path

    assert_response :success
    assert_select "a[href^='javascript:'][href*=?]", "#{capture_url}?url="
  end

  test "ブックマークレットはページの og:image も送る" do
    get bookmarklet_path
    assert_select "a[href^='javascript:'][href*='og:image'][href*='twitter:image'][href*='&image=']"
  end

  test "送られてきた画像は、認識できたときも種類を選ばせるときも引き継ぐ" do
    image = "https://img.example.com/a.jpg"
    get capture_path(url: MAPS_URL, title: "芦屋の割烹 - Google マップ", image:)
    assert_redirected_to new_place_path(subject: { title: "芦屋の割烹", lat: "34.7275", lng: "135.305", url: MAPS_URL, image_url: image })

    get capture_path(url: "https://example.com/x", title: "何かのページ", image:)
    assert_select "a[href=?]", new_book_path(subject: { title: "何かのページ", url: "https://example.com/x", image_url: image })
    assert_select "a[href=?]", new_dish_path(subject: { title: "何かのページ", recipe_url: "https://example.com/x", image_url: image })
  end

  test "画像が無い・http(s) でないときは引き継がない" do
    get capture_path(url: MAPS_URL, title: "芦屋の割烹 - Google マップ", image: "")
    assert_redirected_to new_place_path(subject: { title: "芦屋の割烹", lat: "34.7275", lng: "135.305", url: MAPS_URL })

    get capture_path(url: MAPS_URL, title: "芦屋の割烹 - Google マップ", image: "javascript:alert(1)")
    assert_redirected_to new_place_path(subject: { title: "芦屋の割烹", lat: "34.7275", lng: "135.305", url: MAPS_URL })
  end
end
