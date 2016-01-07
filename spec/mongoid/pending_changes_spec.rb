require 'spec_helper'


class Test
  include Mongoid::PendingChanges
  field      :name,                type: String
  field      :age,                 type: Integer
  field      :telephones,          type: Array
  appendable :telephones

  field      :emails,               type: Array

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

      #1
      test.push_for_approval name: 'John',
                             age: 30

      #2
      test.push_for_approval name: 'Mary',
                             age: 50

      #3
      test.push_for_approval age: 10

      #4 - appendable - single
      test.push_for_approval telephones: '123'

      #5 - appendable - array
      test.push_for_approval telephones: %w(999 888 777)

      #6 - non-appendable
      test.push_for_approval emails: %w(email@email.com)
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
      expect(Test.last.get_change_number(2)[:backup][:name]).to eq 'Old name'
    end

    it 'records the time that the change was applied' do
      Test.last.apply_change 3
      expect(Test.last.get_change_number(3)[:updated_at]).to  be_within(1).of(Time.now)
    end

    it 'appends single value on appendable fields' do
      Test.last.update_attribute :telephones, %w(111 222 333)
      Test.last.apply_change 4
      expect(Test.last.telephones).to eq %w(111 222 333 123)
    end

    it 'appends all values on appendable fields' do
      Test.last.update_attribute :telephones, %w(111 222 333)
      Test.last.apply_change 5
      expect(Test.last.telephones).to eq %w(111 222 333 999 888 777)
    end

    it 'replaces non-appendable fields' do
      Test.last.update_attribute :emails, %w(m@email.com a@email.com)
      Test.last.apply_change 6
      expect(Test.last.emails).to eq %w(email@email.com)
    end

  end

  describe '#reject_change' do
    before :each do
      test = Test.create! name: 'Old name'

      test.push_for_approval name: 'John',
                             age: 30

      test.push_for_approval age: 10
    end

    it 'does not apply change' do
      Test.last.reject_change 1
      expect(Test.last.name).to eq 'Old name'
    end

    it 'adds any info we provide' do
      Test.last.reject_change 2, {status: 'Rejected'}
      expect(Test.last.name).to eq 'Old name'
    end

    it 'records the time that the change was rejected' do
      Test.last.reject_change 1
      expect(Test.last.get_change_number(1)[:updated_at]).to  be_within(1).of(Time.now)
    end

  end

end
