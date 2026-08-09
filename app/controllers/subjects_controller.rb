class SubjectsController < ApplicationController
  def show
    @subject = Subject.find(params[:id])
    @events = @subject.events.includes(:cause).order(occurred_on: :desc, id: :desc)
    @state = CurrentState.find_by(id: @subject.id)
    @event = Event.new(type: "did", occurred_on: Date.current)
  end
end
