# ブックマークレットの着地点。どちらの場合も保存はしない。
#
# - ページそのものを認識できたら、値を埋めたフォームへ飛ばす
# - できなければ、ページ内のリンクのうち認識できるものを候補に出し、種類も選ばせる
#
# ページの扱い: 文字を選んで押したか、リンクから候補を選んだなら、ページは何かを紹介している側なので
# イベントの「出どころ」にする。何も選ばずに押したなら、ページそのもの (店の公式サイトなど) かもしれないので
# 対象の URL にする。ページの og:image はページそのものを対象にするときだけ引き継ぐ。
# 認識器が画像を決めていればそちらを優先する (SPA ではページの og:image が古いまま残るため)。
class CapturesController < ApplicationController
  helper_method :choice_params

  def show
    @url = params[:url].to_s
    @title = params[:title].to_s
    @image = { image_url: params[:image] }.select { |_, url| HttpUrl.valid?(url) }
    hit = Capture.recognize(url: @url, title: @title)
    return redirect_to public_send("new_#{hit.kind}_path", subject: @image.merge(hit.subject)) if hit

    @selection = params[:selection].to_s.squish.first(200)
    @candidates = Capture.candidates(Capture.links_from(params[:links]), hint: "#{@selection} #{@title}")
    @name = @selection.presence || Capture.fallback_title(@title)
  end

  private

  # 種類を選んだときにフォームへ渡す値。url_key は対象の URL を入れる欄 (料理だけ recipe_url)。
  def choice_params(url_key)
    return { subject: { title: @name }, source_url: @url } if @selection.present?

    { subject: { title: @name, url_key => @url, **@image } }
  end
end
