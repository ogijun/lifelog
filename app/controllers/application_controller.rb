class ApplicationController < ActionController::Base
  private

  # capture で来た画像 (subject[image_url]) は、記録したときに取り込む。ファイルが選ばれていれば
  # そちらを優先して取りに行かない。取れなくても記録は止めず、取れなかったことだけ返す。
  def attach_captured_cover(subject)
    url = params.dig(:subject, :image_url)
    return if url.blank? || subject.cover.attached?

    "画像は取得できなかった。" unless RemoteImage.attach(subject.cover, url)
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
