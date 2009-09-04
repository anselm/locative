class SolrWorker &lt; Workling::Base
 
  def index_object(options={})
    object = options[:object_type].constantize.find_by_id(options[:object_id])
    unless object.blank?
      object.solr_save
    end
  end
 
  def destroy_object_index(options={})
    object = options[:object_type].constantize.find_by_id(options[:object_id])
    unless object.blank?
      object.solr_destroy
    end
  end
 
end
