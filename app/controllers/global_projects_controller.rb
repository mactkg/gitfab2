class GlobalProjectsController < ApplicationController
  layout "global_projects"

  def index
    q = params[:q]

    if q.present?
      @projects = Project.solr_search do |s|
        s.fulltext q.split.map{|word| "\"#{word}\""}.join " AND "
        s.without :is_private, true
      end.results
      @is_searching = true

    elsif !q.nil?
      @projects = Project.all().in(is_private: [false, nil]).page(params[:page]).order("updated_at DESC")
      @is_searching = true

    else
      @projects = Project.all().in(is_private: [false, nil]).page(params[:page]).order("updated_at DESC")
      @featured_projects = []
      config = YAML.load_file("#{Rails.root}/config/featured-projects.yml")
      if config
        config.each do |id|
          project = Project.find(id)
          if project
            @featured_projects << project
          end
        end
      end
      @is_searching = false
    end


    @_projects = Project.all().in(is_private: [false, nil])
    @selected_tags = []
    file_path = "#{Rails.root}/config/selected-tags.yml"

    tags_list = YAML.load_file file_path
    file = File::stat file_path

    if tags_list.present? && file.atime - file.mtime < 60 * 60
      tags_list.each do |tag_name|
        @selected_tags.push tag_name
      end
    else
      tag_counters = {}
      @_projects.each do |project|
        project.tags.each do |tag|
          if tag_counters.keys.include? tag.name
            tag_counters[tag.name] += 1
          else
            tag_counters.store tag.name, 1
          end
        end
      end

      File.open(file_path, "w"){|file| file = nil}
      yml_file = File.open file_path, "w"

      if tag_counters.length > 15
        used_tags = Hash[tag_counters.sort{|(k1, v1), (k2, v2)| v2 <=> v1 }]
        used_tags.keys.slice(0, 15).each do |tag_name|
          @selected_tags.push tag_name
          yml_file.puts "- #{tag_name}"
        end
      else
        tag_counters.keys.each do |tag_name|
          @selected_tags.push tag_name
          yml_file.puts "- #{tag_name}"
        end
      end

      yml_file.close

    end

  end
end
