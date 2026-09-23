require "test_helper"

class GoogleMapsUrlTest < ActiveSupport::TestCase
  PLACE_URL = "https://www.google.com/maps/place/%E8%8A%A6%E5%B1%8B%E3%81%AE+%E5%89%B2%E7%83%B9/" \
              "@34.7270,135.3040,17z/data=!3m1!4b1!4m6!3m5!1s0x6000f1:0x2a!8m2!3d34.7275!4d135.305!16s%2Fg%2F11x?entry=ttu"

  test "店名と座標を取り出す" do
    found = GoogleMapsUrl.parse(PLACE_URL)
    assert_equal "芦屋の 割烹", found.name
    assert_equal 34.7275, found.lat
    assert_equal 135.305, found.lng
  end

  test "座標は画面中心の @ ではなく店の !3d!4d を使う" do
    assert_not_equal 34.7270, GoogleMapsUrl.parse(PLACE_URL).lat
  end

  test "座標が無ければ店名だけ" do
    found = GoogleMapsUrl.parse("https://www.google.co.jp/maps/place/%E5%89%B2%E7%83%B9/")
    assert_equal "割烹", found.name
    assert_nil found.lat
    assert_nil found.lng
  end

  test "南半球・西半球の負の座標" do
    found = GoogleMapsUrl.parse("https://www.google.com/maps/place/x/data=!3d-33.86!4d-151.2")
    assert_equal [ -33.86, -151.2 ], [ found.lat, found.lng ]
  end

  test "店のページでなければ nil" do
    assert_nil GoogleMapsUrl.parse("https://tabelog.com/hyogo/A2803/")
    assert_nil GoogleMapsUrl.parse("https://www.google.com/maps/search/%E5%89%B2%E7%83%B9/")
    assert_nil GoogleMapsUrl.parse("https://maps.app.goo.gl/abc123")
    assert_nil GoogleMapsUrl.parse("https://evil.example/maps/place/x/")
    assert_nil GoogleMapsUrl.parse("")
    assert_nil GoogleMapsUrl.parse(nil)
  end

  test "壊れた %エンコードは nil" do
    assert_nil GoogleMapsUrl.parse("https://www.google.com/maps/place/%E8%ZZ/")
    assert_nil GoogleMapsUrl.parse("https://www.google.com/maps/place/%FF%FE/")
  end

  test "定数をトップレベルに漏らさない" do
    assert_not Object.const_defined?(:PLACE, false)
  end
end
