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

    end
  end
end
