# 記録の対象。本・映画・料理・店・動画を同一テーブルで扱う。
# 種類固有の属性は external_ids と同様に JSON へ逃がし、マイグレーションを不要にする。
class Subject < ApplicationRecord
  KINDS = %w[book film dish place video].freeze

  has_many :events, dependent: :destroy
  # 対象の顔になる画像 (表紙・サムネイル・外観など)。1枚だけ。保存先は Active Storage に任せる。
  has_one_attached :cover

  COVER_TYPES = %w[image/jpeg image/png image/webp image/gif image/avif].freeze

  serialize :external_ids, coder: JSON, type: Hash

  attribute :external_ids, default: -> { {} }

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true
  validate :cover_is_image

  before_create { self.id ||= ShortId.generate }

  private

  def cover_is_image
    return unless cover.attached?

    errors.add(:cover, "は画像にしてください") unless COVER_TYPES.include?(cover.content_type)
  end
end
