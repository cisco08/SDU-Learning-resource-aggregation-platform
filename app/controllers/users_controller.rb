class UsersController < ApplicationController
  require "json"
  include KnowledgesHelper
  
  before_action :confirm_logged_in, only: [:index, :edit, :update]
  before_action :confirm_access, only: [:edit, :update, :edit_config, :update_config]
  before_action :confirm_is_admin, only: [:destroy, :ban, :unban]
  
  def new
    @user = User.new
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def create
    @user = User.new(user_param)
    @user.user_role = USER_ROLE_STUDENT
    if @user.save
      flash[:success] = "欢迎, #{@user.username}!"
      log_in @user
      remember @user
      
      redirect_to user_url(@user)
    else
      render 'new'
    end
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_param)
      flash[:success] = "成功更新用户信息！"
      redirect_to @user
    else
      render 'edit'
    end
  end
  
  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @users = User.all.paginate(page: page, per_page: per_page)
  end
  
  def destroy
    @user =  User.find(params[:id])
    @result = @user.destroy
    respond_to do |format|
      format.html { render "show" }
      format.js
    end
  end
  
  def ban
    @user = User.find(params[:id])
    @result = @user.update_attribute(:ban, true)
    respond_to do |format|
      format.html { render "show" }
      format.js
    end
  end
  
  def unban
    @user = User.find(params[:id])
    @result = @user.update_attribute(:ban, false)
    respond_to do |format|
      format.html { render "show" }
      format.js
    end
  end
  
  def contents_notify
    @user = User.find(params[:id])
    @notifications = nil
  end
  
  def edit_config
    @user = User.find(params[:id])
    @config = @user.user_config
  end
  
  def update_config
    @user = User.find(params[:id])
    @config = @user.user_config
    result = {}
    # update course notification config
    param = params[:user_config]
    dict = {}
    ["Resource", "Question", "Blog"].each do |ele|
      dict[ele] = param[("course_"+ele.downcase).to_s]=="1"
    end
    result[:courses_notification_config]=dict.to_json
    # update knowledge notification config
    dict = {}
    dict["Reply"] = param[:knowledge_reply]=="1"
    result[:knowledges_notification_config]=dict.to_json
    
    if @config.update_attributes(result)
      flash[:success] = "更新设置成功！"
      redirect_to edit_config_user_path(@user)
    else
      flash[:danger] = "更新失败，未知原因错误"
      render 'users/edit_config'
    end
  end
  
  def create_following
    @user = User.find(params[:id])
    @following = User.find(params[:following])
    @result = @user.followings<<@following
    @index = params[:index]
    respond_to do |format|
      format.html { render "show" }
      format.js
    end
  end
  
  def delete_following
    @user = User.find(params[:id])
    @following = User.find(params[:following])
    @index = params[:index]
    @result = UserFollowAssociation.find_by(following: @user, followed: @following).destroy
    
    respond_to do |format|
      format.html {render("show")}
      format.js
    end
  end
  
  def followings
    @user = User.find(params[:id])
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    @followings = @user.followings.paginate(page: page, per_page: per_page)
  end
    
  def followeds
    @user = User.find(params[:id])
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    @followeds = @user.followeds.paginate(page: page, per_page: per_page)
  end
  
  def selected_courses
    @user = User.find(params[:id])
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    @courses = @user.selected_courses.paginate(page: page, per_page: per_page)
  end
  
  def select_course
    @user = User.find(params[:id])
    if @user.user_role.to_s == 'teacher'
      @result = :teacher
      respond_to do |format|
        format.html { render "show" }
        format.js
      end
    else
      @course = Course.find(params[:course])
      @result = @user.selected_courses<<@course
      @index = params[:index]
      respond_to do |format|
        format.html { render "show" }
        format.js
      end
    end

  end
  
  def unselect_course
    @user = User.find(params[:id])
    if @user.user_role.to_s == 'teacher'
      @result = :teacher
      respond_to do |format|
        format.html { render "show" }
        format.js
      end
    else
      @course = Course.find(params[:course])
      @index = params[:index]
      
      # @result = UserCourseAssociation.find_by(user: @user, course: @course).destroy
      @result = @user.selected_courses.delete(@course)
      
      respond_to do |format|
        format.html {render("show")}
        format.js
      end
    end
  end
  
  def creatings
    @user = User.find(params[:id])
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    query = params[:type] || [TYPE_QUESTION, TYPE_BLOG, TYPE_RESOURCE]
    @creatings = @user.creatings.where(type: query).paginate(page: page, per_page: per_page)
  end
  
  def focuses
    @user = User.find(params[:id])
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    query = params[:type] || [TYPE_QUESTION, TYPE_BLOG, TYPE_RESOURCE]
    @creatings = @user.focus_contents.where(type: query).paginate(page: page, per_page: per_page)
  end
  
  def chart
    @user = User.find(params[:id])
    
    @post_count = @user.get_creating_count(rule: params[:post_rule], n: params[:post_n])
    @type_count = @user.get_type_count
  end
  
  def knowledge_graph_demo
    @user = User.find(params[:id])
    if knowledge_graph = @user.calc_knowledge_graph
      
      if @user.interest
        @interest_arr = @user.interest.split(";").map do |string|
          Course.where(course_name: string)[0]
        end
        puts @interest_arr
      end
      
      @knowledge_vetex = knowledge_graph[0]
      @knowledge_edge = knowledge_graph[1]
      render "knowledge_graph_demo"
      
    else
      render "knowledge_graph_empty"
    end
    
  end
  
  private
    def user_param
      params.require(:user).permit(:username, :email, :password,
                                  :password_confirmation, :phone_number,
                                  :user_role, :nickname, :birthday,
                                  :sex, :grade, :user_class, :self_introduce,
                                  :speciality, :department)
    end
    
    def config_param
      params.require(:user_config).permit(:course_blog, :course_resource, :course_question, :knowledge_reply)
    end
    

    
end
