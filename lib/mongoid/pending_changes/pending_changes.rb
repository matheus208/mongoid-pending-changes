require 'mongoid'

module Mongoid
  module PendingChanges
    extend ActiveSupport::Concern
    GLOBAL_PENDING_CHANGES_FLAG = 'mongoid_pending_changes_enabled'
    included do
      include Mongoid::Document

      field :version, type: Integer
      field :last_version, type: Integer
      field :changelist, type: Array

      before_create do
        self.version = 0
        self.last_version = 0
        self.changelist = []
      end


      def push_for_approval(changes, meta = {})
        #TODO Think of multithreading?
        self.last_version = (self.last_version || 0) + 1

        version = meta.merge number: self.last_version,
                             data: changes,
                             time: Time.now,
                             approved: false

        self.changelist = [] unless self.changelist
        self.changelist.push version

        self.save
      end

      def get_change_number(number)
        return unless number && self.changelist
        self.changelist.each do |cl|
          return cl if cl[:number] == number
        end
      end

      def apply_change(number, meta = {})
        return unless number
        new_changelist = self.changelist.map do |cl|
                            if cl[:number] == number
                              #Apply the changes to the main object and return the old values
                              backup = apply(cl[:data])
                              #Merge the change with the meta
                              cl.merge! meta
                              #Set the backup and other fields
                              cl[:backup] = backup
                              cl[:time] = Time.now
                              cl[:approved] = true
                            end
                            cl
                        end
        self.changelist = new_changelist
      end

      private
        def apply(data)
          backup = {}

          #For each data we want to update...
          data.each do |field, value|
            #if it exists, back it up
            if self[field]
              backup[field] = self[field]
            end
            #Update
            self[field] = value
          end

        end

    end
  end
end
