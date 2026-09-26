# http(s) でホストのある URL か。リンクやプレビューに出してよいかの判定に使う
# (javascript: などを href / src に入れないため)。名前解決はしない。
module HttpUrl
  module_function

  def valid?(url)
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
