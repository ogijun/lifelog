require "resolv"

# 短縮 URL (X の t.co、Amazon の amzn.to など) の行き先を調べる。
# 決めたホストだけに問い合わせ、応答の Location を読むだけで行き先にはつながない。
# 接続の守りは SafeHttp。問い合わせるとサービス側からは「クリックした」ように見える。
module ShortLink
  HOSTS = %w[t.co amzn.to amzn.asia a.co bit.ly].freeze
  MAX = 10 # 1回のキャプチャで問い合わせる数の上限 (画面を遅くしないため)
  TIMEOUT = 3 # 秒

  module_function

  def short?(url)
    HOSTS.include?(URI.parse(url.to_s).host)
  rescue URI::InvalidURIError
    false
  end

  # 行き先の URL。短縮 URL でない・分からないときは nil。
  def expand(url, resolver: SafeHttp.method(:resolve), http: method(:get))
    return unless short?(url)

    uri = SafeHttp.parse(url)
    long = http.call(uri, SafeHttp.public_address(uri.host, resolver))
    long if HttpUrl.valid?(long)
  rescue StandardError => e
    # 1件の失敗 (名前解決のエラーや変な応答など) で、キャプチャの画面ごと落とさない。
    Rails.logger.info("ShortLink could not expand #{url}: #{e.class}: #{e.message}")
    nil
  end

  # まとめて並行に調べる。{ 短縮 URL => 行き先 } (分かったものだけ)。
  def expand_all(urls, expand: method(:expand))
    urls.select { short?(it) }.uniq.first(MAX)
        .map { |url| Thread.new { [ url, expand.call(url) ] } }
        .map(&:value).select(&:last).to_h
  end

  def get(uri, ip) = SafeHttp.get(uri, ip, timeout: TIMEOUT) { location(it) }

  def location(response) = (response["location"] if response.is_a?(Net::HTTPRedirection))
end
