require 'rails_helper'

RSpec.describe UserDisplayNameJob, type: :job do
  let! :user do
    create :user
  end

  let! :like do
    create :like, user: user
  end

  before :each do
    like.update_columns(display_name: 'A different name')
  end

  it 'updates cached display names on likes' do
    expect do
      UserDisplayNameJob.perform_now(user.id)
    end.to change { like.reload.display_name }.to(user.display_name)
  end
end