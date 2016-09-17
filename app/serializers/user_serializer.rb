class UserSerializer < ActiveModel::Serializer
  cache expires_in: 3.hours

  attribute :id
  attribute :deleted_by_id, if: :can_view_deleted_users?

  attribute :display_name
  attribute :created_at
  attribute :last_active_at

  attribute :email, if: :can_view_users_personal_fields?
  attribute :email_confirmed_at, if: :can_view_users_personal_fields?

  attribute :first_name, if: :can_view_users_personal_fields?
  attribute :last_name, if: :can_view_users_personal_fields?
  attribute :date_of_birth, if: :can_view_users_personal_fields?

  attribute :characters_count
  attribute :created_characters_count
  attribute :posts_count do
    # Unless the viewer is an admin, show only visible post count.
    current_user.try(:admin?) ? object.posts_count : object.visible_posts_count
  end

  attribute :banned
  attribute :deleted

  attribute :avatar_url, if: -> { object.avatar.file.present? } do
    object.avatar.url
  end
  attribute :avatar_medium_url, if: -> { object.avatar.medium.file.present? } do
    object.avatar.medium.url
  end
  attribute :avatar_thumb_url, if: -> { object.avatar.thumb.file.present? } do
    object.avatar.thumb.url
  end

  belongs_to :deleted_by, serializer: UserSerializer, if: :can_view_deleted_users?

  def can_view_users_personal_fields?
    object.id == current_user.try(:id) ||
    current_user.try(:allowed_to?, :view_users_personal_fields)
  end

  def can_view_deleted_users?
    current_user.try(:allowed_to?, :view_deleted_users)
  end
end
