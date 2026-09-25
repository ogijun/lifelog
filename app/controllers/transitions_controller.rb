# 状態を次に進めるボタン。日付は押した時点の「今日」をサーバが決める
# (ページを開いたまま日付をまたいでも正しくなるように、画面からは送らない)。
class TransitionsController < ApplicationController
  def create
    subject = Subject.find(params[:subject_id])
    Recorder.append(subject, type: params[:type], occurred_on: FuzzyDate.from_date(Date.current))
    redirect_to subject, status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to subject, status: :see_other, alert: e.record.errors.full_messages.to_sentence
  end
end
