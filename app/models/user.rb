class User < ActiveRecord::Base
  acts_as_authentic

  # Paperclip
  has_attached_file :photo,
    :styles => {
      :thumb=> "100x100#",
      :small => "150x150>"
    }

end
