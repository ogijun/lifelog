# ブックマークレットの着地点。どちらの場合も保存はしない。
#
# - ページそのものを認識できたら、値を埋めたフォームへ飛ばす
# - できなければ、ページ内のリンクのうち認識できるものを候補に出し、種類も選ばせる
#
# ページの扱い: 文字を選んで押した、SNS の投稿、og:type が article、リンクから候補を選んだ、のどれかなら、
# ページは何かを紹介している側なのでイベントの「出どころ」にする。そうでなければページそのもの
# (店の公式サイトなど) かもしれないので対象の URL にする。ページの og:image はどちらでも画像の候補に出す
# (SNS の投稿の写真は、たいていその店や料理)。フォームのチェックで外せる。
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
    @candidates = Capture.candidates(Capture.links_from(params[:links]), hint: "#{@selection} #{@title}",
                                                                         expand: ShortLink.method(:expand_all))
    @name = @selection.presence || Capture.fallback_title(@title)
    @source = @selection.present? || Capture.source_page?(url: @url, og_type: params[:type].to_s)
  end

  private

  # 種類を選んだときにフォームへ渡す値。url_key は対象の URL を入れる欄 (料理だけ recipe_url)。
  # ページが出どころなら、名前は選んだ文字だけ (本は『』も)。投稿の本文まるごとは名前にしない。
  def choice_params(kind, url_key)
    return { subject: { title: @name, url_key => @url, **@image } } unless @source

    title = @selection.presence || (kind == :book ? Capture.bracketed(@title).to_s : "")
    { subject: { title:, **@image }, source_url: @url }
  end
end
