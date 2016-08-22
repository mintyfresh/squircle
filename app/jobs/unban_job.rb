class UnbanJob
  @queue = :medium

  def self.perform
    User.banned.no_active_bans.find_each do |user|
      user.update banned: false
    end
  end
end
