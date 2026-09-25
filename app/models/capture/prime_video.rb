# Prime Video の作品ページ。primevideo.com のタイトルは「Prime Video: 〇〇」。
# amazon.co.jp 側は「〇〇を観る | Prime Video」(2026-09 に実物で確認)。「Amazon.co.jp: 」が付く形も外す。
# amazon.co.jp の /dp/ は本と同じ形なので、タイトルが Prime Video のものだけ当てる。
module Capture
  module PrimeVideo
    PRIMEVIDEO = %r{\Ahttps://(?:www\.)?primevideo\.com/(?:[^?#]*/)?detail/([A-Z0-9]+)}
    AMAZON_DETAIL = %r{\Ahttps://(?:www\.)?amazon\.co\.jp/gp/video/detail/([A-Z0-9]{10})}
    AMAZON_DP = %r{\Ahttps://(?:www\.)?amazon\.co\.jp/(?:[^?#]*/)?dp/([A-Z0-9]{10})}
    SUFFIX = / \| Prime Video\z/

    module_function

    def call(url:, title:)
      url = canonical_url(url, title) or return
      name = title.sub(/\APrime Video: /, "").sub(/\AAmazon\.co\.jp\s*[:：]\s*/, "").sub(SUFFIX, "").delete_suffix("を観る")
      Hit.new(kind: "video", subject: { title: name, url: })
    end

    def canonical_url(url, title)
      if (m = PRIMEVIDEO.match(url))
        "https://www.primevideo.com/detail/#{m[1]}/"
      elsif (m = AMAZON_DETAIL.match(url) || (SUFFIX.match?(title) && AMAZON_DP.match(url)))
        "https://www.amazon.co.jp/gp/video/detail/#{m[1]}/"
      end
    end
  end
end
