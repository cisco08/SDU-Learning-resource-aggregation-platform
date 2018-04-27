
module NotificationsHelper
    # constants
    # how to use: NotificationsHelper::ENTITY_TYPE_COURSE
    ENTITY_TYPE_COURSE = "course"
    ENTITY_TYPE_QUESTION = "question"
    ENTITY_TYPE_BLOG = "blog"
    ENTITY_TYPE_RESOURCE = "resource"
    ENTITY_TYPE_REPLY = "reply"
    
    NOTIFY_TYPE_GOOD = "good"
    NOTIFY_TYPE_BAD = "bad"
    NOTIFY_TYPE_DELETED = "deleted"
    NOTIFY_TYPE_REPLY = "reply"
    NOTIFY_TYPE_BOUTIQUED = "boutiqued"
    NOTIFY_TYPE_PASS = "pass"
    NOTIFY_TYPE_REFUSE ="refuse"
    NOTIFY_TYPE_UPDATE = "update"
    NOTIFY_TYPE_NEW = "new"
    
    NOTIFY_MAX_RESERVE = 50
    
    # functions
    def generate_notification!(user, notify_entity, options={})
        if user && notify_entity
            notification = user.notifications.build(options)
            notification.notify_entity_id = notify_entity.id
            if user.notifications.count >= NOTIFY_MAX_RESERVE
                # wating for test
                user.notifications[0].destroy
            end
            
            notification.save
        end
    end
    
    def get_notifications!(user)
        if user
            check_notification user
            list = user.notifications
            user.notifications.clear
            list
        end
    end
    
    def norrow_notify_entity(notification)
       if notification
          case notification.entity_type
            when ENTITY_TYPE_COURSE
              Course.find(notification.notify_entity_id)
            when ENTITY_TYPE_QUESTION
              Question.find(notification.notify_entity_id)
            when ENTITY_TYPE_BLOG
              BLOG.find(notification.notify_entity_id)
            when ENTITY_TYPE_REPLY
              REPLY.find(notification.notify_entity_id)
            when ENTITY_TYPE_RESOURCE
              RESOURCE.find(notification.notify_entity_id)
          end
       end
    end
    
    def check_notification(user)
      return unless user
      
      # get user's config, if it is nil, set all option to default.
      if user.user_config
        if user.user_config.courses_notification_config
          course_config = JSON::parse(user.user_config.courses_notification_config)
        else
          course_config = {Resource: true,
                          Blog: true,
                          Question: true}
        end
      end
      
      time = user.last_check_time || Time.now
      
      # find all knowledge in user selected course and in user_config
      course_config = course_config.delete_if {|key, var| var.nil?||var==false}
      
      # check courses user has followed
      user.selected_courses.each do |course|
        knowledges_need_notify = course.knowledges.where(type: course_config.keys).where(
                                "knowledges.created_at>?",time)
                
        knowledges_need_notify.each do |knowledge|
          generate_notification!(user, course,
                                notify_type: NOTIFY_TYPE_NEW,
                                entity_type: ENTITY_TYPE_COURSE,
                                with_entity_id: knowledge.id,
                                with_entity_type: knowledge.type)
        end
      end
      
      # check knowledges user has followed
      knowledges_need_notify = user.focus_contents.where("knowledges.updated_at>?",time)
      knowledges_need_notify.each do |knowledge|
        generate_notification!(user, knowledge,
                              notify_type: NOTIFY_TYPE_UPDATE,
                              entity_type: knowledge.type)
      end
      
      user.update_check_time
    end
    
end
