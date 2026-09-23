# 本の記録。films / dishes / places とほぼ同じ形をしているが、意図的に統合しない。
# 1つのフォームに「今どの種類か」という状態を持たせないための重複。
class BooksController < ApplicationController
  before_action { @causes = Timeline.recent(limit: 50) }

  def new
    # /capture から subject パラメータ付きで来たら値を埋める。保存はしない。
    @subject = Subject.new(params.key?(:subject) ? subject_params : { kind: "book" })
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
    p = params.expect(subject: [ :title, :creator, :isbn, :url ])
    { kind: "book", title: p[:title], creator: p[:creator],
      external_ids: { "isbn" => p[:isbn], "url" => p[:url] }.compact_blank }
  end

  def event_params
    params.expect(event: [ :type, :occurred_on, :rating, :note, :caused_by ]).to_h.symbolize_keys
  end
end
