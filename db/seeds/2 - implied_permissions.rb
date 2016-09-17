
{
  # - Bans - #
  view_deleted_bans: :view_bans,
  view_bans:         :view_owned_bans,

  # - Characters - #
  view_deleted_characters: :view_characters,
  update_characters:       :update_owned_characters,
  delete_characters:       :delete_owned_characters,

  # - Users - #
  view_deleted_users: :view_users,
  update_users:       :update_self,
  delete_users:       :delete_self
}.each do |name, implied|
  permission = Permissible::Permission.find_by!(name: name)

  Array.wrap(implied).each do |name|
    implied = Permissible::Permission.find_by!(name: implied)
    next if permission.implied_permissions.exists?(id: implied)

    permission.implied_permissions << implied
  end
end
