# 状態を次に進めるボタン。
#
# 詳細ページでは、ボタンと同じフォームに日付の欄があり、最初は「今日」が入っている。そのまま押せば
# 押した時点の今日で記録し、書き換えればその日付 (曖昧でもよい)、空にすれば不明で記録する。
# 欄に入れておくのが数字の日付ではなく「今日」という言葉なのは、ページを開いたまま日付をまたいでも
# 押した時点で読まれるようにするため。今日の候補の行は欄なしで、今日で記録する。
class TransitionsController < ApplicationController
  def create
    subject = Subject.find(params[:subject_id])
    Recorder.append(subject, type: params[:type], occurred_on:)
    redirect_to subject, status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to subject, status: :see_other, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def occurred_on
    text = params.key?(:event) ? params.expect(event: [ :occurred_on ])[:occurred_on] : "今日"
    FuzzyTimestamp.parse(text, now: Time.current)
  end
end
