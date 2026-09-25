require "test_helper"

class RemoteImageTest < ActiveSupport::TestCase
  PNG = Rails.root.join("test/fixtures/files/cover.png").binread
  PUBLIC_IP = "93.184.215.14"

  def resolver(*ips) = ->(_host) { ips }

  # 本物の通信の代わり。渡された接続先 (IP) を覚えておき、決まった本文を返す。
  def http(body = PNG)
    calls = []
    fake = ->(uri, ip) { calls << [ uri.to_s, ip ]; body }
    [ fake, calls ]
  end

  def fetch(url, ips: [ PUBLIC_IP ], body: PNG)
    fake, calls = http(body)
    [ RemoteImage.fetch(url, resolver: resolver(*ips), http: fake), calls ]
  end

  test "公開アドレスの画像を取り、形式は中身の先頭バイトで決める" do
    image, calls = fetch("https://img.example.com/a.jpg?x=1")

    assert_equal "image/png", image.content_type
    assert_equal PNG, image.io.read
    assert_equal "cover.png", image.filename
    assert_equal [ [ "https://img.example.com/a.jpg?x=1", PUBLIC_IP ] ], calls
  end

  test "名前解決した IP に直接つなぐ (途中で DNS を差し替えられても内部に向かない)" do
    _, calls = fetch("https://img.example.com/a.png")
    assert_equal PUBLIC_IP, calls.sole.last
  end

  test "http(s) 以外は拒否" do
    [ "javascript:alert(1)", "file:///etc/passwd", "ftp://img.example.com/a.png", "//img.example.com/a.png", "", nil ].each do |url|
      assert_raises(RemoteImage::Refused, url.inspect) { fetch(url) }
    end
  end

  test "内部向けのアドレスは拒否" do
    %w[127.0.0.1 10.0.0.5 172.16.0.1 192.168.1.1 169.254.169.254 100.64.0.1 0.0.0.0 ::1 fd00::1 fe80::1 ::ffff:127.0.0.1].each do |ip|
      assert_raises(RemoteImage::Refused, ip) { fetch("https://img.example.com/a.png", ips: [ ip ]) }
    end
  end

  test "解決したアドレスに1つでも内部向けがあれば拒否" do
    assert_raises(RemoteImage::Refused) { fetch("https://img.example.com/a.png", ips: [ PUBLIC_IP, "127.0.0.1" ]) }
  end

  test "名前解決できなければ拒否" do
    assert_raises(RemoteImage::Refused) { fetch("https://nowhere.invalid/a.png", ips: []) }
  end

  test "中身が画像でなければ拒否 (拡張子やヘッダは信じない)" do
    assert_raises(RemoteImage::Refused) { fetch("https://img.example.com/a.png", body: "<html>not an image</html>") }
  end

  test "本文は上限まで読み、超えたら拒否" do
    ok = Net::HTTPOK.new("1.1", "200", "OK")
    ok.define_singleton_method(:read_body) { |&block| 3.times { block.call("x" * 10) } }
    assert_equal 30, RemoteImage.read_limited(ok, max_bytes: 30).bytesize
    assert_raises(RemoteImage::Refused) { RemoteImage.read_limited(ok, max_bytes: 29) }
  end

  test "成功以外の応答 (リダイレクトを含む) は追わずに拒否" do
    [ Net::HTTPFound.new("1.1", "302", "Found"), Net::HTTPNotFound.new("1.1", "404", "Not Found") ].each do |res|
      assert_raises(RemoteImage::Refused, res.code) { RemoteImage.read_limited(res) }
    end
  end
end
