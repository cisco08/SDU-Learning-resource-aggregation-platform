class Keyword < ApplicationRecord

#   关联关系 属于某一课程
  has_many :course_keyword_associations, dependent: :destroy
  has_many :courses, through: :course_keyword_associations
  
  has_many :user_keyword_associations, dependent: :destroy
  has_many :users, through: :user_keyword_associations
  
  has_many :keyword_knowledge_associations, dependent: :destroy
  has_many :knowledges, through: :keyword_knowledge_associations
  
  has_many :higher_relationships, class_name:  "KeywordRelationship",
                                   foreign_key: "lower_id",
                                   dependent:   :destroy
                                   
  has_many :highers, through: :higher_relationships,  source: :higher, inverse_of: :lowers
  
  has_many :lower_relationships, class_name:  "KeywordRelationship",
                                   foreign_key: "higher_id",
                                   dependent:   :destroy
                                   
  has_many :lowers, through: :lower_relationships,  source: :lower, inverse_of: :highers

  def Keyword.getFirstLayer(content)
    re = Array.new
    content.each do|k|
      if k.highers.empty?
        re << k
      end
    end
    return re
  end
end
