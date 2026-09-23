require "test_helper"

class CaptureTest < ActiveSupport::TestCase
  test "当たった認識器の結果を返す" do
    hit = Capture.recognize(url: "https://www.google.com/maps/place/%E5%89%B2%E7%83%B9/", title: "割烹 - Google マップ")
    assert_equal "place", hit.kind
  end

  test "どの認識器にも当たらなければ nil" do
    assert_nil Capture.recognize(url: "https://example.com/", title: "何かのページ")
  end
end
