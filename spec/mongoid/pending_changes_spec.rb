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

  describe '#push_for_approval' do
    context 'without additional information' do
      before :each do
        test = Test.create! name: 'Test name',
                            age: 20
        test.push_for_approval(name: 'Test new name')
      end

      it{expect(Test.last.version).to eq 0}
      it{expect(Test.last.last_version).to eq 1}
      it{expect(Test.last.changelist.count).to be 1 }
      it{expect(Test.last.changelist[0][:number]).to be 1 }
      it{expect(Test.last.changelist[0][:time]).to be_within(1).of(Time.now) }
      it{expect(Test.last.changelist[0][:data][:name]).to eq 'Test new name' }
      it{expect(Test.last.changelist[0][:approved]).to be false }
    end
    context 'with additional information' do
      before :each do
        test = Test.create! name: 'Test name',
                            age: 20
        test.push_for_approval({name: 'Test new name'}, {source: 'test', rank: 55.5, awesome: true})
      end

      it{expect(Test.last.changelist[0][:source]).to eq 'test' }
      it{expect(Test.last.changelist[0][:rank]).to eq 55.5 }
      it{expect(Test.last.changelist[0][:awesome]).to be true }

    end
  end

end
