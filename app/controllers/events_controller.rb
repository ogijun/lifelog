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
    @events = @subject.events.includes(:cause).order(occurred_on: :desc, id: :desc)
    @state = CurrentState.find_by(id: @subject.id)
    render "subjects/show", status: :unprocessable_entity
  end

  private

  def event_params
    params.expect(event: [ :type, :occurred_on, :rating, :note, :caused_by ]).to_h.symbolize_keys
  end
end
