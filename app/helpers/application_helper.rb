module ApplicationHelper
  def viewing_as
    session[:role] ? session[:role] : "guest"
  end

  def login_logout
    if session[:role] == 'player'
      link_to('logout', File.join(matches_path, '?player=false'))
    else
      link_to('login', File.join(matches_path, '?player=true'))
    end
  end

  def resize_state_labels(hash_in, style)
    hash_in.each_with_object({}) do |label, hash_out|
      event = label.first
      label_type = label.last
      hash_out[event] = label_type + '" style="' + style + '"'
    end
  end
  module_function :resize_state_labels
end
