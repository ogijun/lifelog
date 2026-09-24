# 既存 subject への遷移の追記。Turbo Stream で一覧と状態だけ差し替える。
class EventsController < ApplicationController
  def create
    @subject = Subject.find(params[:subject_id])
    @event = Recorder.append(@subject, **event_params)
    @state = CurrentState.find_by(id: @subject.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @subject }
    end
  rescue ActiveRecord::RecordInvalid => e
    @event = e.record
    @events = @subject.events.includes(:cause).order(occurred_on: :desc, created_at: :desc, id: :desc)
    @state = CurrentState.find_by(id: @subject.id)
    render "subjects/show", status: :unprocessable_entity
  end

  # 日付・評価・メモだけ直せる。種別 (type) は追記のみなので受け取らない。
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
    p = params.expect(event: [ :occurred_year, :occurred_month, :occurred_day, :rating, :note ])
    { rating: p[:rating], note: p[:note],
      occurred_on: FuzzyDate.from_parts(year: p[:occurred_year], month: p[:occurred_month], day: p[:occurred_day]) }
  end

  def event_params
    p = params.expect(event: [ :type, :occurred_year, :occurred_month, :occurred_day, :rating, :note, :caused_by ])
    { type: p[:type], rating: p[:rating], note: p[:note], caused_by: p[:caused_by],
      occurred_on: FuzzyDate.from_parts(year: p[:occurred_year], month: p[:occurred_month], day: p[:occurred_day]) }
  end
end
