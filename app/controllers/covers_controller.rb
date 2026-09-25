# 詳細ページからの、対象の画像の差し替えと削除。
class CoversController < ApplicationController
  before_action { @subject = Subject.find(params[:subject_id]) }

  def update
    if @subject.cover.attach(params.expect(:cover))
      redirect_to @subject, status: :see_other
    else
      redirect_to @subject, status: :see_other, alert: @subject.errors.full_messages.to_sentence
    end
  end

  def destroy
    @subject.cover.purge
    redirect_to @subject, status: :see_other
  end
end
