# == Schema Information
#
# Table name: reports
#
#  id              :integer          not null, primary key
#  reportable_type :string           not null
#  reportable_id   :integer          not null
#  status          :string           default("open"), not null
#  description     :text
#  creator_id      :integer          not null
#  deleted         :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_reports_on_creator_id                         (creator_id)
#  index_reports_on_deleted                            (deleted)
#  index_reports_on_reportable_type_and_reportable_id  (reportable_type,reportable_id)
#  index_reports_on_status                             (status)
#

class Report < ActiveRecord::Base
  belongs_to :reportable, polymorphic: true
  belongs_to :creator, class_name: 'User'

  enum status: {
    open:     'open',
    resolved: 'resolved',
    wontfix:  'wontfix',
    spite:    'spite'
  }

  validates :reportable, presence: true
  validates :creator, presence: true

  validates :status, presence: true
  validates :description, presence: true, length: { in: 10..1_000 }

  scope :visible, -> {
    where deleted: false
  }
end