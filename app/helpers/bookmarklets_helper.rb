module BookmarkletsHelper
  SOURCE = Rails.root.join("app/javascript/bookmarklet.js")

  # app/javascript/bookmarklet.js を javascript: の1行にし、送り先 (このホストの /capture) を埋める。
  def bookmarklet_href
    code = SOURCE.read.gsub(%r{/\*.*?\*/}m, "").gsub(/\s+/, " ").strip
    "javascript:#{code.sub('CAPTURE_URL', capture_url.to_json)}"
  end
end
