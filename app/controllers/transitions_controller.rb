# 状態を次に進める。
#
# - ボタン (type だけ): 押した時点の「今日」で記録する。日付はサーバが決める
#   (ページを開いたまま日付をまたいでも正しくなるように、画面からは送らない)
# - 「日付や評価を指定して記録」(new → event[...]): 曖昧な日付・評価・メモ・出どころを指定して記録する
class TransitionsController < ApplicationController
  before_action { @subject = Subject.find(params[:subject_id]) }

  def new
    status = CurrentState.find_by(id: @subject.id)&.status
    @event = Event.new(type: Event::NEXT_TYPES.fetch(status, Event::TYPES).first, occurred_on: today)
  end

  def create
    Recorder.append(@subject, **event_params)
    redirect_to @subject, status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @event = e.record
    return render :new, status: :unprocessable_entity if params.key?(:event)

    redirect_to @subject, status: :see_other, alert: @event.errors.full_messages.to_sentence
  end

  private

  def today = FuzzyTimestamp.from_date(Date.current)

  def event_params
    return { type: params[:type], occurred_on: today } unless params.key?(:event)

    p = params.expect(event: [ :type, :occurred_on, :rating, :note, :source_url ])
    { type: p[:type], rating: p[:rating], note: p[:note], source_url: p[:source_url],
      occurred_on: FuzzyTimestamp.parse(p[:occurred_on], now: Time.current) }
  end
end
