# Google マップの店ページ。URL の文字列を読むだけで、外部にはリクエストしない。
module Capture
  module GoogleMaps
    PLACE = %r{\Ahttps://(?:www\.)?google\.[a-z.]+/maps/place/([^/?#]+)}
    # @lat,lng は画面の中心。店そのものの座標は data 部の !3d / !4d にある。
    COORDS = /!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/

    module_function

    def call(url:, title:)
      place = PLACE.match(url) or return
      name = URI.decode_www_form_component(place[1])
      return unless name.valid_encoding?

      lat, lng = COORDS.match(url)&.captures
      Hit.new(kind: "place", subject: { title: name, lat:, lng:, url: }.compact)
    rescue ArgumentError
      nil
    end
  end
end
