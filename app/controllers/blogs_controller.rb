require "knowledges_controller"
require 'will_paginate/array'
class BlogsController < KnowledgesController
    include ApplicationHelper
    before_action :record_visit, only: [:show]
    skip_before_filter :verify_authenticity_token, :only => [:render_keyword,:render_department,:render_spe,:render_newCourse,:render_label]
    def index
        @blog = Blog.all
        @blog = @blog.where("check_state=?",1)
        @blog = @blog.sort_by{ |created_at| created_at }.reverse
        @blog = @blog.paginate(:page => params[:page], :per_page => 4)
    end
    def destroy
        @blog = Blog.find(params[:id])
        @blog.destroy
        redirect_to blogs_path
    end
    def new
        super
        @blog = Blog.new
        @keywords = Keyword.all
    end
    def show
        @knowledge = Knowledge.find(params[:id])
        @knowledge.visit_count = @knowledge.visit_count+1
        @knowledge.save
    end
    def edit
        @blog = Blog.find(params[:id])
        @courses =  Course.all
        @keywords = Keyword.all
    end
    def create
        @blog = Blog.new(blog_params);
        @blog.check_state = 0
        # src = @blog.content.match("<img\b[^<>]*?\bsrc[\s\t\r\n]*=[\s\t\r\n]*[""']?[\s\t\r\n]*(?<imgUrl>[^\s\t\r\n""'<>]*)[^<>]*?/?[\s\t\r\n]*>")
        # if(@blog.knowledge_digest.nil?||@blog.knowledge_digest.empty?)
        #     @blog.knowledge_digest = short_digest(@blog.content,50) 
        # end
        
        b = true;
        if @blog.save
            keyword_list = params[:keywords];
            if !keyword_list.nil?
                keyword_list.each do |key|
                    keyword_knowledge_relationships = @blog.keyword_knowledge_associations.create
                    keyword_knowledge_relationships.keyword = Keyword.find(key)
                    keyword_knowledge_relationships.save
                end
            else
                b = false;
                flash[:notice] = '无关联关键词'
                redirect_to :back
                return 
            end
            course_list = params[:courses];
            if !course_list.nil?
                course_list.each do |c|
                    course_knowledge_relationships = @blog.course_knowledge_associations.create
                    course_knowledge_relationships.course = Course.find(c)
                    course_knowledge_relationships.save
                end
            else
                b = false;
                flash[:notice] = '无关联课程'
                redirect_to :back
                return
            end
            if b
                if(params[:autoGenerate].to_s=="YES")
                    DigestJob.perform_later @blog.content_without_html
                end
                redirect_to blog_path(@blog)
                return
            end
        else
            flash[:notice] = '不合法的参数'
            redirect_to :back
            return
        end
    end
   def update
        @blog = Blog.find(params[:id])
        @blog.check_state = 0
        b = true;
          if @blog.update(blog_params)
            if((@blog.knowledge_digest.nil?||@blog.knowledge_digest.empty?))
                @blog.knowledge_digest = short_digest(@blog.content,50) 
            end
            redirect_to blog_path(@blog)
            keyword_list = params[:keywords];
            course_list = params[:courses];
            
            if keyword_list.nil?
                b = false;                
                flash[:notice] = '无关联关键词'
            end
            
            if course_list.nil?
                b = false; 
                flash[:notice] = '无关联课程'
            end
            
            if b
                @blog.keywords.each do |key|
                    if !keyword_list.include?(key)
                            @blog.keywords.delete(key);
                    end
                end
                @blog.courses.each do |c|
                    if !course_list.include?(c)
                            @blog.courses.delete(c);
                    end
                end
                if !keyword_list.nil?
                    keyword_list.each do |key|
                        keyword_knowledge_relationships = @blog.keyword_knowledge_associations.create
                        keyword_knowledge_relationships.keyword = Keyword.find(key)
                        keyword_knowledge_relationships.save
                    end
                end
                if !course_list.nil?
                    course_list.each do |c|
                        
                        course_knowledge_relationships = @blog.course_knowledge_associations.create
                        course_knowledge_relationships.course = Course.find(c)
                        course_knowledge_relationships.save
                    end
                end
            else
                  if(params[:autoGenerate].to_s=="YES")
                    DigestJob.perform_later @blog.content_without_html
                  end
                  render :edit 
                  return
            end
          else
             flash[:notice] = '不合法的参数'
             render :edit
             return
          end
    end

private
    # Never trust parameters from the scary internet, only allow the white list through.
    def blog_params
      params.require(:blog).permit(:user_id,:title, :type,:content, :good, :bad,:knowledge_digest,:label,:autoGenerate)
    end
end
