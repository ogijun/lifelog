# 映画の記録。books / dishes / places / videos のコピー。DESIGN.md の通り統合しない。
class FilmsController < ApplicationController
  before_action { @causes = Timeline.recent(limit: 50) }

  def new
    # /capture から subject パラメータ付きで来たら値を埋める。保存はしない。
    @subject = Subject.new(params.key?(:subject) ? subject_params : { kind: "film" })
    @event = Event.new(type: "wished", occurred_on: FuzzyDate.from_date(Date.current), source_url: params[:source_url])
    @image_url = params.dig(:subject, :image_url)
  end

  def create
    @event = Recorder.start(subject: subject_params, event: event_params)
    redirect_to @event.subject, notice: attach_captured_cover(@event.subject)
  rescue ActiveRecord::RecordInvalid
    @image_url = params.dig(:subject, :image_url)
    @subject = Subject.new(subject_params)
    @event = Event.new(event_params)
    @subject.validate
    @event.validate
    render :new, status: :unprocessable_entity
  end

  private

  def subject_params
    p = params.expect(subject: [ :title, :creator, :tmdb, :url, :cover ])
    { kind: "film", title: p[:title], creator: p[:creator], cover: p[:cover],
      external_ids: { "tmdb" => p[:tmdb], "url" => p[:url] }.compact_blank }
  end

  def event_params
    p = params.expect(event: [ :type, :occurred_on, :rating, :note, :caused_by, :source_url ])
    { type: p[:type], rating: p[:rating], note: p[:note], caused_by: p[:caused_by], source_url: p[:source_url],
      occurred_on: FuzzyDate.parse(p[:occurred_on]) }
  end
end
