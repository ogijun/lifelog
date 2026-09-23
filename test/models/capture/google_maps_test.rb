require "test_helper"

class Capture::GoogleMapsTest < ActiveSupport::TestCase
  PLACE_URL = "https://www.google.com/maps/place/%E8%8A%A6%E5%B1%8B%E3%81%AE+%E5%89%B2%E7%83%B9/" \
              "@34.7270,135.3040,17z/data=!3m1!4b1!4m6!3m5!1s0x6000f1:0x2a!8m2!3d34.7275!4d135.305!16s%2Fg%2F11x?entry=ttu"

  def recognize(url) = Capture::GoogleMaps.call(url:, title: "x - Google マップ")

  test "店として店名・座標・元 URL を返す" do
    hit = recognize(PLACE_URL)
    assert_equal "place", hit.kind
    assert_equal({ title: "芦屋の 割烹", lat: "34.7275", lng: "135.305", url: PLACE_URL }, hit.subject)
  end

  test "座標は画面中心の @ ではなく店の !3d!4d を使う" do
    assert_not_equal "34.7270", recognize(PLACE_URL).subject[:lat]
  end

  test "座標が無ければ店名と URL だけ" do
    url = "https://www.google.co.jp/maps/place/%E5%89%B2%E7%83%B9/"
    assert_equal({ title: "割烹", url: }, recognize(url).subject)
  end

  test "南半球・西半球の負の座標" do
    subject = recognize("https://www.google.com/maps/place/x/data=!3d-33.86!4d-151.2").subject
    assert_equal [ "-33.86", "-151.2" ], subject.values_at(:lat, :lng)
  end

  test "店のページでなければ nil" do
    assert_nil recognize("https://tabelog.com/hyogo/A2803/")
    assert_nil recognize("https://www.google.com/maps/search/%E5%89%B2%E7%83%B9/")
    assert_nil recognize("https://maps.app.goo.gl/abc123")
    assert_nil recognize("https://evil.example/maps/place/x/")
    assert_nil recognize("")
  end

  test "壊れた %エンコードは nil" do
    assert_nil recognize("https://www.google.com/maps/place/%E8%ZZ/")
    assert_nil recognize("https://www.google.com/maps/place/%FF%FE/")
  end

  test "定数をトップレベルに漏らさない" do
    assert_not Object.const_defined?(:PLACE, false)
  end
end
