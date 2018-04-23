class Knowledge < ApplicationRecord
  # association
  belongs_to :creator,class_name: :User, inverse_of: :creatings, foreign_key: :creator_id
  
  has_many :course_knowledge_associations
  has_many :courses, through: :course_knowledge_associations
      
  has_many :keyword_knowledge_associations
  has_many :keywords, through: :keyword_knowledge_associations
  
  has_many :replies, class_name: :Reply, inverse_of: :topic
  
  has_many :focus_knowledge_associations
  has_many :followers, through: :focus_knowledge_associations

  
  # class method
  def self.inherited(child)
      child.instance_eval do
        def model_name
          Knowledge.model_name
        end
      end
    super
  end
  def Knowledge.get_all_entry(entry_type)
    Knowledge.where(:type => entry_type).all
  end
  
  # instance method
  def get_followers
    followers
  end
  
end
