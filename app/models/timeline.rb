# 時系列に全部並ぶだけの一覧。kind をまたいで一本の線になることが要点。
module Timeline
  module_function

  def recent(kind: nil, limit: 200)
    scope = Event.includes(:subject, :cause).order(occurred_on: :desc, id: :desc).limit(limit)
    kind.present? ? scope.where(subject: { kind: }).references(:subject) : scope
  end
end
