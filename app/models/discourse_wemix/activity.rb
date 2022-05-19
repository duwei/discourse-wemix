module DiscourseWemix
  class Activity < ActiveRecord::Base
    self.table_name = 'discourse_wemix_activities'

    belongs_to :user
  end
end
