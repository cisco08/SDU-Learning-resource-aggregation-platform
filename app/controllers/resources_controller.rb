require "knowledges_controller"

class ResourcesController < KnowledgesController
    def index
        @resource = Resource.all
        @resource = Resource.paginate(:page => params[:page], :per_page => 4)
    end
    def new
        super
        @resource = Resource.new
        @keywords = Keyword.all
    end
     def show
        resources = Resource.all
        @knowledge = resources[params[:id].to_i-1]
        if @knowledge.nil?
            @knowledge = Knowledge.find(params[:id])
        end
    end
     def edit
        @resource = Resource.find(params[:id])
        @courses =  Course.all
        @keywords = Keyword.all
    end
    def destroy
        @resource = Resource.find(params[:id])
        @resource.destroy
        redirect_to :back
    end
    def create
        @resource = Resource.new(resource_params);
        filename = uploadfile(params[:resource][:attachment])  
        @resource.attachment = filename  
        if @resource.save
            keyword_list = params[:keywords];
            if !keyword_list.nil?
                keyword_list.each do |key|
                    keyword_knowledge_relationships = @resource.keyword_knowledge_associations.create
                    keyword_knowledge_relationships.keyword = Keyword.find(key)
                    keyword_knowledge_relationships.save
                end
            else
                b = false;
                flash[:notice] = '无关联关键词'
                redirect_to :back
            end
            course_list = params[:courses];
            if !course_list.nil?
                course_list.each do |c|
                    course_knowledge_relationships = @resource.course_knowledge_associations.create
                    course_knowledge_relationships.course = Course.find(c)
                    course_knowledge_relationships.save
                end
            else
                b = false;
                flash[:notice] = '无关联课程'
                redirect_to :back
            end
            if b
                redirect_to resource_path(@resource)
            end
        else
            flash[:notice] = '不合法的参数'
            redirect_to :back
        end
    end
    def update
        @resource = Resource.find(params[:id])
        if !params[:resource][:attachment].nil?
             filename = uploadfile(params[:resource][:attachment])  
             @resource.attachment = filename  
        end
         b = true;
        respond_to do |format|
          if @resource.update(resource_params)
            redirect_to resource_path(@resource)
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
                @resource.keywords.each do |key|
                    if !keyword_list.include?(key)
                            @resource.keywords.delete(key);
                    end
                end
                @resource.courses.each do |c|
                    if !course_list.include?(c)
                            @resource.courses.delete(c);
                    end
                end
                if !keyword_list.nil?
                    keyword_list.each do |key|
                        keyword_knowledge_relationships = @resource.keyword_knowledge_associations.create
                        keyword_knowledge_relationships.keyword = Keyword.find(key)
                        keyword_knowledge_relationships.save
                    end
                end
                if !course_list.nil?
                    course_list.each do |c|
                        
                        course_knowledge_relationships = @resource.course_knowledge_associations.create
                        course_knowledge_relationships.course = Course.find(c)
                        course_knowledge_relationships.save
                    end
                end
            else
                format.html { render :edit } and return
            end
          else
             flash[:notice] = '不合法的参数'
             format.html { render :edit } and return
          end
        end
        
    end
    def file_download  
        resource = Resource.find(params[:r_id])  
        send_file "#{Rails.root}/public/upload/#{resource[:attachment]}"
    end  
    def file_delete  
        resource = Resource.find(params[:r_id])  
        file_path = "#{Rails.root}/public/upload/#{resource[:attachment]}";
        if File.exist?(file_path)
            File.delete(file_path)
            resource.attachment = nil
            resource.save
        end
        redirect_to edit_resource_path(params[:r_id])
    end  
     private
    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id,:title, :type,:content, :good, :bad)
    end
    def uploadfile(file)  
        if !file.original_filename.empty?  
          @filename = file.original_filename  
          #设置目录路径，如果目录不存在，生成新目录  
          FileUtils.mkdir("#{Rails.root}/public/upload") unless File.exist?("#{Rails.root}/public/upload")  
          #写入文件  
          ##wb 表示通过二进制方式写，可以保证文件不损坏  
          File.open("#{Rails.root}/public/upload/#{@filename}", "wb") do |f|  
            f.write(file.read)  
          end  
          return @filename  
        end  
    end  
end
