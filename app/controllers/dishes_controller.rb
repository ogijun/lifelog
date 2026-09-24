# 料理の記録。books / films / places のコピー。DESIGN.md の通り統合しない。
class DishesController < ApplicationController
  before_action { @causes = Timeline.recent(limit: 50) }

  def new
    # /capture から subject パラメータ付きで来たら値を埋める。保存はしない。
    @subject = Subject.new(params.key?(:subject) ? subject_params : { kind: "dish" })
    @event = Event.new(type: "wished", occurred_on: FuzzyDate.from_date(Date.current))
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
    p = params.expect(event: [ :type, :occurred_year, :occurred_month, :occurred_day, :rating, :note, :caused_by ])
    { type: p[:type], rating: p[:rating], note: p[:note], caused_by: p[:caused_by],
      occurred_on: FuzzyDate.from_parts(year: p[:occurred_year], month: p[:occurred_month], day: p[:occurred_day]) }
  end
end
