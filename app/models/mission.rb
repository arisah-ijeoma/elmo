class Mission < ActiveRecord::Base
  has_many(:responses, :inverse_of => :mission)
  has_many(:forms, :inverse_of => :mission)
  has_many(:report_reports, :class_name => "Report::Report", :inverse_of => :mission)
  has_many(:options, :inverse_of => :mission)
  has_many(:option_sets, :inverse_of => :mission)
  has_many(:questions, :inverse_of => :mission)
  has_many(:form_types, :inverse_of => :mission)
  has_many(:broadcasts, :inverse_of => :mission)
  has_many(:settings, :inverse_of => :mission, :dependent => :destroy)
  has_many(:assignments, :inverse_of => :mission)
  
  before_validation(:create_compact_name)
  before_destroy(:check_assoc)
  
  validates(:name, :presence => true)
  validates(:name, :format => {:with => /^[a-z][a-z0-9 ]*$/i, :message => "can only contain letters, numbers, and spaces"},
                   :length => {:minimum => 3, :maximum => 32},
                   :if => Proc.new{|m| !m.name.blank?})
  validate(:compact_name_unique)
  
  scope(:sorted_by_name, order("name"))
  scope(:sorted_recent_first, order("created_at DESC"))
  scope(:active_for_user, lambda{|u| where("missions.id IN (SELECT mission_id FROM assignments WHERE user_id = ? AND active = 1)", u.id)})
  
  private
    def create_compact_name
      self.compact_name = name.gsub(" ", "").downcase
    end
    
    def compact_name_unique
      if !name.blank? && matching = (self.class.where(:compact_name => compact_name).all - [self]).first
        errors.add(:name, "is too much like the existing mission '#{matching.name}'")
      end
    end
    
    def check_assoc
      to_check = [:assignments, :responses, :forms, :report_reports, :options, :option_sets, :questions, :form_types, :broadcasts]
      to_check.each{|a| raise "This mission has associated objects and can't be deleted." unless self.send(a).empty?}
    end
end