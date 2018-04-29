class Player < ActiveRecord::Base
  belongs_to :team
  validates_presence_of :name, :steam_id

  rails_admin do
    list do
      field :id
      field :name
      field :steam_id do
        formatted_value do
          bindings[:view].link_to bindings[:object].steam_id, "http://steamcommunity.com/profiles/#{bindings[:object].steam_id}"
        end
      end
      field :team
    end
    show do
      field :id
      field :name
      field :steam_id do
        formatted_value do
          bindings[:view].link_to bindings[:object].steam_id, "http://steamcommunity.com/profiles/#{bindings[:object].steam_id}"
        end
      end
      field :team
    end
    edit do
      field :id do read_only true end
      field :name
      field :steam_id
      field :team
    end
  end
end
