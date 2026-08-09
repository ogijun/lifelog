# 料理の記録。books / films / places のコピー。DESIGN.md の通り統合しない。
class DishesController < ApplicationController
  before_action { @causes = Timeline.recent(limit: 50) }

  def new
    @subject = Subject.new(kind: "dish")
    @event = Event.new(type: "wished", occurred_on: Date.current)
  end

  def create
    @event = Recorder.start(subject: subject_params, event: event_params)
    redirect_to @event.subject
  rescue ActiveRecord::RecordInvalid
    @subject = Subject.new(subject_params)
    @event = Event.new(event_params)
    @subject.validate
    @event.validate
    render :new, status: :unprocessable_entity
  end

  private

  def subject_params
    p = params.expect(subject: [ :title, :creator, :recipe_url ])
    { kind: "dish", title: p[:title], creator: p[:creator],
      external_ids: { "recipe_url" => p[:recipe_url] }.compact_blank }
  end

  def event_params
    params.expect(event: [ :type, :occurred_on, :rating, :note, :caused_by ]).to_h.symbolize_keys
  end
end
