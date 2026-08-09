class TimelineController < ApplicationController
  def index
    @kind = params[:kind].presence
    @events = Timeline.recent(kind: @kind)
  end
end
