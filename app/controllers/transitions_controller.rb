# 状態を次に進めるボタン。
#
# ふだんはボタンだけで、押した時点の今日で記録する。詳細ページでは、細かく入れたいときだけ開く欄
# (日付・評価・メモ) が同じフォームにあり、開いて書き換えてから同じボタンを押すと一緒に記録する。
# 日付の欄は最初「今日」という言葉が入っている (数字の日付ではないので、ページを開いたまま日付を
# またいでも押した時点で読まれる)。閉じたままなら「今日・評価なし・メモなし」が送られるだけ。
class TransitionsController < ApplicationController
  def create
    subject = Subject.find(params[:subject_id])
    Recorder.append(subject, type: params[:type], **detail)
    redirect_to subject, status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to subject, status: :see_other, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def detail
    return { occurred_on: FuzzyTimestamp.from_date(Date.current) } unless params.key?(:event)

    p = params.expect(event: [ :occurred_on, :rating, :note ])
    { occurred_on: FuzzyTimestamp.parse(p[:occurred_on], now: Time.current), rating: p[:rating], note: p[:note] }
  end
end
