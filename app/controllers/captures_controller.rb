# ブックマークレットの着地点。認識できたら値を埋めたフォームへ飛ばし、
# できなければ種類を選ばせる。どちらも保存はしない。
class CapturesController < ApplicationController
  def show
    @url = params[:url].to_s
    @title = params[:title].to_s
    hit = Capture.recognize(url: @url, title: @title)
    redirect_to public_send("new_#{hit.kind}_path", subject: hit.subject) if hit
  end
end
