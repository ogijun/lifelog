require "test_helper"

class BookmarkletTest < ActionDispatch::IntegrationTest
  MAPS_URL = "https://www.google.com/maps/place/%E8%8A%A6%E5%B1%8B%E3%81%AE%E5%89%B2%E7%83%B9/" \
             "@34.72,135.30,17z/data=!3m1!4b1!8m2!3d34.7275!4d135.305"

  test "Google マップの URL から店名・座標・元 URL が埋まる" do
    get new_place_path(url: MAPS_URL, title: "芦屋の割烹 - Google マップ")

    assert_response :success
    assert_select "input[name='subject[title]'][value=?]", "芦屋の割烹"
    assert_select "input[name='subject[lat]'][value=?]", "34.7275"
    assert_select "input[name='subject[lng]'][value=?]", "135.305"
    assert_select "input[name='subject[url]'][value=?]", MAPS_URL
  end

  test "Google マップ以外はページタイトルをそのまま店名に入れる" do
    get new_place_path(url: "https://tabelog.com/hyogo/A2803/", title: "芦屋の割烹 - 食べログ")

    assert_select "input[name='subject[title]'][value=?]", "芦屋の割烹 - 食べログ"
    assert_select "input[name='subject[lat]']:not([value])"
    assert_select "input[name='subject[url]'][value=?]", "https://tabelog.com/hyogo/A2803/"
  end

  test "埋めるだけで保存はしない" do
    assert_no_difference "Subject.count" do
      get new_place_path(url: MAPS_URL)
    end
  end

  test "記録すると元 URL が external_ids に入る" do
    post places_path, params: {
      subject: { title: "芦屋の割烹", url: MAPS_URL },
      event: { type: "wished", occurred_on: "2026-01-01" }
    }

    assert_equal MAPS_URL, Subject.find_by!(title: "芦屋の割烹").external_ids["url"]
  end

  test "ブックマークレットのページはこのホスト宛てのリンクを出す" do
    get bookmarklet_path

    assert_response :success
    assert_select "a[href^='javascript:'][href*=?]", "#{new_place_url}?url="
  end
end
