# 外部の画像 (capture で送られてきた og:image など) を1枚取ってくる。
# 接続の守り (SSRF 対策) は SafeHttp。ここではさらに:
#
# - リダイレクトは追わない (追った先を検査し直す手間より、og:image は直リンクで足りる)
# - 大きさに上限。形式はヘッダや拡張子ではなく中身の先頭バイトで決める
#
# 取れなければ Refused を投げる。呼び出し側は記録を止めずに画像だけ諦める。
module RemoteImage
  Refused = SafeHttp::Refused

  Fetched = Data.define(:io, :content_type, :filename)

  MAX_BYTES = 5.megabytes

  module_function

  def fetch(url, resolver: Resolv.method(:getaddresses), http: method(:get))
    uri = SafeHttp.parse(url)
    body = http.call(uri, SafeHttp.public_address(uri.host, resolver))
    content_type = Marcel::MimeType.for(StringIO.new(body))
    raise Refused, "画像ではない (#{content_type})" unless Subject::COVER_TYPES.include?(content_type)

    Fetched.new(io: StringIO.new(body), content_type:, filename: "cover.#{content_type.split('/').last}")
  end

  # capture で来た URL の画像を attachment (subject.cover) に付ける。取れなければ false。
  def attach(attachment, url)
    image = fetch(url)
    attachment.attach(io: image.io, filename: image.filename, content_type: image.content_type)
    true
  rescue Refused => e
    Rails.logger.info("RemoteImage refused #{url}: #{e.message}")
    false
  end

  def get(uri, ip) = SafeHttp.get(uri, ip) { read_limited(it) }

  def read_limited(response, max_bytes: MAX_BYTES)
    raise Refused, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    body = +""
    response.read_body do |chunk|
      body << chunk
      raise Refused, "#{max_bytes} バイトを超えた" if body.bytesize > max_bytes
    end
    body
  end
end
