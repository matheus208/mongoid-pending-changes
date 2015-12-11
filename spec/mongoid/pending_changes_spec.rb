require 'spec_helper'

describe Mongoid::PendingChanges do
  it 'has a version number' do
    expect(Mongoid::PendingChanges::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
