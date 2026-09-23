# Google マップの店ページの URL から、店名と座標を取り出す。
# URL の文字列を読むだけで、外部にはリクエストしない (外部 API 連携は未実装のまま)。
class GoogleMapsUrl < Data.define(:name, :lat, :lng)
  PLACE = %r{\Ahttps://(?:www\.)?google\.[a-z.]+/maps/place/([^/?#]+)}
  # @lat,lng は画面の中心。店そのものの座標は data 部の !3d / !4d にある。
  COORDS = /!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/

  def self.parse(url)
    place = PLACE.match(url.to_s) or return
    name = URI.decode_www_form_component(place[1])
    return unless name.valid_encoding?

    lat, lng = COORDS.match(url)&.captures&.map(&:to_f)
    new(name:, lat:, lng:)
  rescue ArgumentError
    nil
  end
end
