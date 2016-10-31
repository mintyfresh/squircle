# frozen_string_literal: true
# == Schema Information
#
# Table name: posts
#
#  id              :integer          not null, primary key
#  body            :text             not null
#  author_id       :integer          not null
#  editor_id       :integer
#  character_id    :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deleted         :boolean          default(FALSE), not null
#  conversation_id :integer          not null
#  formatted_body  :text
#  deleted_by_id   :integer
#  deleted_at      :datetime
#
# Indexes
#
#  index_posts_on_author_id        (author_id)
#  index_posts_on_character_id     (character_id)
#  index_posts_on_conversation_id  (conversation_id)
#  index_posts_on_deleted_by_id    (deleted_by_id)
#  index_posts_on_editor_id        (editor_id)
#
# Foreign Keys
#
#  fk_rails_10b14ebdc2  (author_id => users.id)
#  fk_rails_5736a68073  (deleted_by_id => users.id)
#  fk_rails_9108cfb061  (conversation_id => conversations.id)
#  fk_rails_9a8220b37a  (character_id => characters.id)
#  fk_rails_9db77e9c1f  (editor_id => users.id)
#

class Post < ApplicationRecord
  include Formattable
  include SoftDeletable

  alias_attribute :user_id, :author_id

  belongs_to :author, class_name: 'User', inverse_of: :posts
  belongs_to :editor, class_name: 'User'
  belongs_to :character, inverse_of: :posts

  belongs_to :conversation, inverse_of: :posts
  has_one :section, through: :conversation

  validates :author, presence: true
  validates :conversation, presence: true
  validates :body, presence: true, length: { in: 10..10_000, if: :body? }

  formattable :body

  before_commit :set_posts_counts
  before_commit :set_conversation_last_activity

  scope :first_post, -> {
    select(<<-SQL.squish)
      first_value("posts"."id")
    OVER
      (PARTITION BY "posts"."conversation_id" ORDER BY "posts"."created_at" ASC)
    SQL
  }

  scope :last_post, -> {
    select(<<-SQL.squish)
      first_value("posts"."id")
    OVER
      (PARTITION BY "posts"."conversation_id" ORDER BY "posts"."created_at" DESC)
    SQL
  }

  scope :flood, -> {
    where Post.arel_table[:created_at].gteq(20.seconds.ago)
  }

  scope :visible, -> {
    not_deleted.where(conversation: Conversation.visible)
  }

private

  def set_posts_counts
    author.set_posts_count
    character&.set_posts_count
    conversation.set_posts_count unless conversation.destroyed?
    section.set_posts_count
  end

  def set_conversation_last_activity
    return if conversation.destroyed?
    last_activity = conversation.posts.not_deleted.maximum(:updated_at)
    conversation.update_columns(last_active_at: last_activity)
  end
end
