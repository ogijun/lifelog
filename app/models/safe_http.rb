require "ipaddr"
require "net/http"
require "resolv"

# 利用者のブラウザから来た URL に、サーバからつなぐときの守り (SSRF 対策)。
# 外部への接続は必ずここを通す (RemoteImage, ShortLink)。
#
# - http(s) だけ
# - 名前解決したアドレスに1つでも内部向けがあれば拒否し、解決した IP に直接つなぐ
#   (つなぐ瞬間に DNS を差し替えて内部へ向ける手口を防ぐ)。NAT64 などの IPv6 に埋め込まれた
#   IPv4 も判定する
# - 環境変数のプロキシは使わない (使うと IP への直接接続が効かなくなる)
# - タイムアウト
#
# つなげなければ Refused を投げる。
module SafeHttp
  class Refused < StandardError; end

  TIMEOUT = 5 # 秒
  DENIED = %w[
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
    192.0.0.0/24 192.168.0.0/16 198.18.0.0/15 224.0.0.0/4 240.0.0.0/4
    ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8 64:ff9b:1::/48
  ].map { IPAddr.new(it) }.freeze
  # NAT64 の既定の接頭辞。IPv6 の形で任意の IPv4 を埋め込める (64:ff9b::7f00:1 = 127.0.0.1)。
  NAT64 = IPAddr.new("64:ff9b::/96")
  NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError ].freeze

  module_function

  # 名前解決。Resolv.getaddresses は DNS に上限時間が無いので、hosts と上限時間付きの DNS を使う。
  def resolve(host)
    dns = Resolv::DNS.new.tap { it.timeouts = TIMEOUT }
    Resolv.new([ Resolv::Hosts.new, dns ]).getaddresses(host)
  ensure
    dns&.close
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

  # 確かめた IP に直接つなぐ。証明書は URL のホスト名で検証される。
  # プロキシは明示的に使わない (既定では環境変数の http_proxy を読み、IP への直接接続が効かなくなる)。
  def connection(uri, ip, timeout: TIMEOUT)
    http = Net::HTTP.new(uri.host, uri.port, nil)
    http.ipaddr = ip
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = http.read_timeout = http.ssl_timeout = timeout
    http
  end

  # GET を送り、応答をブロックに渡す (本文を読むかどうかは呼び出し側が決める)。
  def get(uri, ip, timeout: TIMEOUT)
    http = connection(uri, ip, timeout:)
    http.start { http.request(Net::HTTP::Get.new(uri)) { return yield(it) } }
  rescue *NETWORK_ERRORS => e
    raise Refused, e.class.name
  end
end
