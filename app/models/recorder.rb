# イベント追記。引数で全てを受け取り、インスタンス状態を持たない。
module Recorder
  module_function

  # 新しい subject を、その最初の遷移イベントと一緒に記録する。
  def start(subject:, event:)
    Subject.transaction do
      record = Subject.create!(**subject)
      Event.create!(subject: record, **event)
    end
  end

  # 既存 subject に遷移を追記する。再読・再訪も同じイベントが並ぶだけ。
  def append(subject, **event)
    Event.create!(subject:, **event)
  end
end
