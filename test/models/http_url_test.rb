require "test_helper"

class HttpUrlTest < ActiveSupport::TestCase
  test "http(s) でホストのある URL だけ" do
    assert HttpUrl.valid?("https://example.com/a")
    assert HttpUrl.valid?("http://example.com")
    [ "javascript:alert(1)", "ftp://example.com", "//example.com", "https://", "not a url", "", nil ].each do |url|
      assert_not HttpUrl.valid?(url), url.inspect
    end
  end
end
