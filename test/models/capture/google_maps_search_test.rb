require "test_helper"

class Capture::GoogleMapsSearchTest < ActiveSupport::TestCase
  ADDRESS = "東京都新宿区神楽坂1-2-3"

  def recognize(url, title = "") = Capture::GoogleMapsSearch.call(url:, title:)
  def canonical(query) = "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(query)}"

  test "住所の検索リンクは店の候補。住所を取り出し、URL は検索リンクの正規形" do
    hit = recognize("https://www.google.com/maps/search/?api=1&query=#{CGI.escape(ADDRESS)}")
    assert_equal "place", hit.kind
    assert_equal({ address: ADDRESS, url: canonical(ADDRESS) }, hit.subject)
  end

  test "maps.google.com/?q= や /maps/search/<検索語> の形も" do
    [ "https://maps.google.com/?q=#{CGI.escape(ADDRESS)}", "https://maps.google.co.jp/maps?q=#{CGI.escape(ADDRESS)}",
      "https://www.google.co.jp/maps/search/#{ERB::Util.url_encode(ADDRESS)}/" ].each do |url|
      assert_equal ADDRESS, recognize(url)&.subject&.dig(:address), url
    end
  end

  test "住所らしくない検索語は名前にする" do
    assert_equal({ title: "コ本や", url: canonical("コ本や") },
                 recognize("https://www.google.com/maps/search/?api=1&query=#{CGI.escape('コ本や')}").subject)
  end

  test "リンクの文字があれば名前にする (URL の切れ端でなければ)" do
    assert_equal "コ本や", recognize("https://maps.google.com/?q=#{CGI.escape(ADDRESS)}", "コ本や").subject[:title]
  end

  test "検索語が無い・Google マップでなければ nil" do
    assert_nil recognize("https://www.google.com/maps/search/?api=1")
    assert_nil recognize("https://www.google.com/search?q=#{CGI.escape(ADDRESS)}")
    assert_nil recognize("https://evil.example/maps/search/?api=1&query=x")
  end
end
