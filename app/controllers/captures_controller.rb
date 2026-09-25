# ブックマークレットの着地点。認識できたら値を埋めたフォームへ飛ばし、
# できなければ種類を選ばせる。どちらも保存はしない。
# ページの og:image は種類によらず image_url として引き継ぎ、記録したときに取り込む。
class CapturesController < ApplicationController
  def show
    @url = params[:url].to_s
    @title = params[:title].to_s
    @image = { image_url: params[:image] }.select { |_, url| RemoteImage.http_url?(url) }
    hit = Capture.recognize(url: @url, title: @title)
    return redirect_to public_send("new_#{hit.kind}_path", subject: hit.subject.merge(@image)) if hit

    @title = Capture.fallback_title(@title)
  end
end
