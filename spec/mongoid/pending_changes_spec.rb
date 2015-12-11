require 'spec_helper'


class Test
  include Mongoid::PendingChanges
  field      :name,                type: String
  field      :age,                 type: Integer
  belongs_to :TestRelation
end


class TestRelation
  include Mongoid::PendingChanges
  field       :awesome,           type: Boolean
  has_one     :TestRelation
end


describe Mongoid::PendingChanges do
  describe 'setup' do
    let(:model) {
      Test.create name: 'Test name',
                  age: 20
    }

    it{expect(model.version).to eq 0}
    it{expect(model.last_version).to eq 0}
    it{expect(model.changelist).to eq []}
  end
end
