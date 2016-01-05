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


  describe '#get_change_number' do
    before :each do
      test = Test.create! name: 'Old name',
                          age: 20
      test.push_for_approval name: 'New name 1'

      test.push_for_approval age: 21

      test.push_for_approval name: 'New name 2',
                             age: 22
    end

    it {expect(Test.last.get_change_number(1)[:data][:name]).to eq  'New name 1'}
    it {expect(Test.last.get_change_number(2)[:data][:age]).to eq 21}
    it {expect(Test.last.get_change_number(3)[:number]).to eq 3}

    it {expect(Test.last.get_change_number(0)).to be nil}
    it {expect(Test.last.get_change_number(4)).to be nil}
  end

  describe '#apply_change' do
    before :each do
      test = Test.create! name: 'Old name'

      test.push_for_approval name: 'John',
                             age: 30

      test.push_for_approval name: 'Mary',
                             age: 50
    end

    it 'applies the change by number' do
      Test.last.apply_change 2
      expect(Test.last.name).to eq 'Mary'
    end

    it 'changes the status to approved' do
      Test.last.apply_change 3
      expect(Test.last.get_change_number(3)[:approved]).to be true
    end

    it 'updates other fields if provided' do
      status_text = 'Approved'
      Test.last.apply_change 1, {status: status_text}
      expect(Test.last.get_change_number(1)[:status]).to eq status_text
    end

    it 'backs up the fields that were overwritten by the change' do
      Test.last.apply_change 2
      old = {name: 'Old name'}
      expect(Test.last.get_change_number(2)[:backup]).to eq old
    end

    it 'records the time that the change was applied' do
      Test.last.apply_change 3
      expect(Test.last.get_change_number(3)[:updated_at]).to  be_within(1).of(Time.now)
    end

  end
end
