# 記録したイベントの編集と取り消し。新しいイベントは、記録フォーム (種類ごと) か
# 状態を進めるボタン (TransitionsController) で作る。
class EventsController < ApplicationController
  # 日付・評価・メモ・出どころを直せる。種別 (type) は追記のみなので受け取らない。
  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id])
    if @event.update(edit_params)
      redirect_to @event.subject, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    event = Event.find(params[:id])
    subject = event.subject

    if Recorder.undo(event)
      redirect_to (subject.destroyed? ? root_path : subject), status: :see_other
    else
      redirect_to subject, status: :see_other, alert: "登録から1時間を過ぎたので取り消せない。"
    end
  end

  private

  def edit_params
    p = params.expect(event: [ :occurred_on, :rating, :note, :source_url ])
    { rating: p[:rating], note: p[:note], source_url: p[:source_url], occurred_on: FuzzyTimestamp.parse(p[:occurred_on], now: Time.current) }
  end
end
