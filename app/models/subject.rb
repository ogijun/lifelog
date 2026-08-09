# 記録の対象。本・映画・料理・場所を同一テーブルで扱う。
# 種類固有の属性は external_ids と同様に JSON へ逃がし、マイグレーションを不要にする。
class Subject < ApplicationRecord
  KINDS = %w[book film dish place].freeze

  has_many :events, dependent: :destroy

  serialize :external_ids, coder: JSON, type: Hash

  attribute :external_ids, default: -> { {} }

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true

  before_create { self.id ||= SecureRandom.uuid }
end
