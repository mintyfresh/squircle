# == Schema Information
#
# Table name: bans
#
#  id         :integer          not null, primary key
#  reason     :string           not null
#  expires_at :datetime
#  user_id    :integer          not null
#  creator_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  waived     :boolean          default(FALSE), not null
#
# Indexes
#
#  index_bans_on_creator_id  (creator_id)
#  index_bans_on_user_id     (user_id)
#

class Ban < ActiveRecord::Base
  belongs_to :user, inverse_of: :bans
  belongs_to :creator, class_name: 'User'

  attr_readonly :user_id
  attr_readonly :creator_id

  validates :user, presence: true
  validates :creator, presence: true
  validates :reason, presence: true

  validate :creator_is_admin, on: :create
  validate :creator_is_not_user, on: :create

  after_create :apply_ban_to_user, unless: :expired?

  scope :active, -> {
    where Ban.arel_table[:waived]
             .eq(false)
             .and(
               Ban.arel_table[:expires_at]
                  .eq(nil)
                  .or(
                    Ban.arel_table[:expires_at]
                       .gteq(Time.zone.now)
                  )
             )
  }

  scope :inactive, -> {
    where Ban.arel_table[:waived]
             .eq(true)
             .or(
               Ban.arel_table[:expires_at]
                  .not_eq(nil)
                  .and(
                    Ban.arel_table[:expires_at]
                       .lt(Time.zone.now)
                  )
             )
  }

  scope :permanent, -> {
    where expires_at: nil
  }

  def active?
    !waived? && !expired?
  end

  def expired?
    expires_at.present? && expires_at.past?
  end

  def permanent?
    expires_at.nil?
  end

  alias_method :expired, :expired?
  alias_method :permanent, :permanent?

  def creator_is_admin
    errors.add :creator, 'must be an admin user' unless creator.try(:admin?)
  end

  def creator_is_not_user
    errors.add :base, 'you cannot ban yourself' if user_id == creator_id
  end

  def apply_ban_to_user
    user.update! banned: true unless expired?
  end
end
