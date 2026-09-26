require "test_helper"

class ShortLinkTest < ActiveSupport::TestCase
  PUBLIC_IP = "104.244.42.5"

  def resolver(*ips) = ->(_host) { ips }

  # 本物の通信の代わり。問い合わせ先を覚えておき、決まった Location を返す。
  def http(location)
    calls = []
    [ ->(uri, ip) { calls << [ uri.to_s, ip ]; location }, calls ]
  end

  def expand(url, location: "https://www.amazon.co.jp/dp/4101005052", ips: [ PUBLIC_IP ])
    fake, calls = http(location)
    [ ShortLink.expand(url, resolver: resolver(*ips), http: fake), calls ]
  end

  test "決めた短縮 URL のホストだけが対象" do
    %w[https://t.co/abc https://amzn.to/abc https://amzn.asia/d/abc https://a.co/d/abc https://bit.ly/abc].each do |url|
      assert ShortLink.short?(url), url
    end
    [ "https://example.com/abc", "https://t.co.evil.example/abc", "javascript:alert(1)", nil ].each do |url|
      assert_not ShortLink.short?(url), url.inspect
    end
  end

  test "短縮 URL の Location を読むだけで、行き先にはつながない" do
    long, calls = expand("https://t.co/xTpSKCcmAO")
    assert_equal "https://www.amazon.co.jp/dp/4101005052", long
    assert_equal [ [ "https://t.co/xTpSKCcmAO", PUBLIC_IP ] ], calls
  end

  test "短縮 URL でなければ問い合わせない" do
    long, calls = expand("https://example.com/abc")
    assert_nil long
    assert_empty calls
  end

  test "内部向けのアドレスには問い合わせない" do
    long, calls = expand("https://t.co/abc", ips: [ "127.0.0.1" ])
    assert_nil long
    assert_empty calls
  end

  test "Location が無い・http(s) でないなら nil" do
    assert_nil expand("https://t.co/abc", location: nil).first
    assert_nil expand("https://t.co/abc", location: "javascript:alert(1)").first
  end

  test "解決の途中で想定外の例外が起きても、その1件を諦めるだけ (画面を落とさない)" do
    boom = ->(_uri, _ip) { raise Resolv::ResolvError, "dns" }
    assert_nil ShortLink.expand("https://t.co/abc", resolver: resolver(PUBLIC_IP), http: boom)
    assert_nil ShortLink.expand("https://t.co/abc", resolver: ->(_) { raise Encoding::CompatibilityError }, http: http(nil).first)
  end

  test "Location は応答がリダイレクトのときだけ読む" do
    redirect = Net::HTTPMovedPermanently.new("1.1", "301", "Moved")
    redirect["location"] = "https://www.amazon.co.jp/dp/4101005052"
    ok = Net::HTTPOK.new("1.1", "200", "OK")
    ok["location"] = "https://www.amazon.co.jp/dp/4101005052"

    assert_equal "https://www.amazon.co.jp/dp/4101005052", ShortLink.location(redirect)
    assert_nil ShortLink.location(ok)
  end

  test "まとめて解決するのは短縮 URL だけ、重複を除いて上限まで" do
    urls = [ "https://example.com/a", *Array.new(15) { "https://t.co/#{it}" }, "https://t.co/0" ]
    asked = Concurrent::Array.new
    expansions = ShortLink.expand_all(urls, expand: ->(url) { asked << url; "https://www.amazon.co.jp/dp/#{url[-1]}" })

    assert_equal ShortLink::MAX, asked.size
    assert_equal asked.sort, expansions.keys.sort
    assert_not_includes asked, "https://example.com/a"
  end
end
