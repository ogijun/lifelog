# Google マップの検索リンク。X のプロフィールは「場所」をこの形のリンクで出す。
# 検索語が住所らしければ住所に、そうでなければ名前にする。座標は検索語だけでは分からない
# (住所から座標を出すのは外部 API になる)。
module Capture
  module GoogleMapsSearch
    GOOGLE = %r{\Ahttps://(?:www\.|maps\.)?google\.[a-z.]+/}
    ADDRESS = /[都道府県市区町村]|丁目|番地|〒|\d+-\d+/

    module_function

    def call(url:, title:)
      return unless GOOGLE.match?(url)

      query = query_of(URI.parse(url)) or return
      subject = ADDRESS.match?(query) ? { address: query } : { title: query }
      name = Capture.link_name(title).presence
      Hit.new(kind: "place", subject: { title: name, **subject.compact }.compact.merge(url: search_url(query)))
    rescue URI::InvalidURIError, ArgumentError
      nil
    end

    def query_of(uri)
      params = URI.decode_www_form(uri.query.to_s).to_h
      query =
        if uri.path.start_with?("/maps/search/") && params["api"] == "1" then params["query"]
        elsif (term = uri.path[%r{\A/maps/search/([^/]+)}, 1]) then URI.decode_www_form_component(term)
        elsif uri.host.start_with?("maps.") then params["q"]
        end
      query&.strip.presence
    end

    def search_url(query) = "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(query)}"
  end
end
