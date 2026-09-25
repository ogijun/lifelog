require "ipaddr"
require "net/http"
require "resolv"

# 外部の画像 (capture で送られてきた og:image など) を1枚取ってくる。
# URL は利用者のブラウザから来るので、サーバを内部ネットワークへの踏み台にさせない (SSRF 対策):
#
# - http(s) だけ
# - 名前解決したアドレスに1つでも内部向けがあれば拒否し、解決した IP に直接つなぐ
#   (つなぐ瞬間に DNS を差し替えて内部へ向ける手口を防ぐ)
# - リダイレクトは追わない (追った先を検査し直す手間より、og:image は直リンクで足りる)
# - 時間と大きさに上限。形式はヘッダや拡張子ではなく中身の先頭バイトで決める
#
# 取れなければ Refused を投げる。呼び出し側は記録を止めずに画像だけ諦める。
module RemoteImage
  class Refused < StandardError; end

  Fetched = Data.define(:io, :content_type, :filename)

  MAX_BYTES = 5.megabytes
  TIMEOUT = 5 # 秒
  DENIED = %w[
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
    192.0.0.0/24 192.168.0.0/16 198.18.0.0/15 224.0.0.0/4 240.0.0.0/4
    ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8 64:ff9b:1::/48
  ].map { IPAddr.new(it) }.freeze
  # NAT64 の既定の接頭辞。IPv6 の形で任意の IPv4 を埋め込める (64:ff9b::7f00:1 = 127.0.0.1)。
  NAT64 = IPAddr.new("64:ff9b::/96")

  module_function

  def fetch(url, resolver: Resolv.method(:getaddresses), http: method(:get))
    uri = parse(url)
    body = http.call(uri, public_address(uri.host, resolver))
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

  # プレビューに出してよい URL か (http(s) だけ。名前解決はしない)。
  def http_url?(url)
    parse(url) && true
  rescue Refused
    false
  end

  def parse(url)
    uri = URI.parse(url.to_s)
    raise Refused, "http(s) ではない" unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri
  rescue URI::InvalidURIError
    raise Refused, "URL ではない"
  end

  def public_address(host, resolver)
    addresses = resolver.call(host).map { IPAddr.new(it.to_s) }
    raise Refused, "名前解決できない" if addresses.empty?

    denied = addresses.find { |addr| [ addr, embedded_ipv4(addr) ].compact.any? { |a| DENIED.any? { it.include?(a) } } }
    raise Refused, "内部向けのアドレス (#{denied})" if denied

    addresses.first.to_s
  rescue IPAddr::InvalidAddressError
    raise Refused, "アドレスが不正"
  end

  # IPv6 の形に埋め込まれた IPv4 (IPv4-mapped と NAT64)。
  def embedded_ipv4(addr)
    return addr.native if addr.ipv4_mapped?

    IPAddr.new(addr.to_i & 0xffff_ffff, Socket::AF_INET) if NAT64.include?(addr)
  end

  def get(uri, ip)
    http = connection(uri, ip)
    http.start { http.request(Net::HTTP::Get.new(uri)) { return read_limited(it) } }
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
    raise Refused, e.class.name
  end

  # 確かめた IP に直接つなぐ。証明書は URL のホスト名で検証される。
  # プロキシは明示的に使わない (既定では環境変数の http_proxy を読み、IP への直接接続が効かなくなる)。
  def connection(uri, ip)
    http = Net::HTTP.new(uri.host, uri.port, nil)
    http.ipaddr = ip
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = http.read_timeout = http.ssl_timeout = TIMEOUT
    http
  end

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
