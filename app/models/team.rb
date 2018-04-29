class Team < ActiveRecord::Base
  has_many :players
  has_and_belongs_to_many :matches
  belongs_to :tournament

  validates_presence_of :name, :tag

  rails_admin do
    list do
      field :id
      field :name
      field :tag
      field :players
    end
    show do
      field :id
      field :name
      field :tag
      field :players
      field :matches
    end
    edit do
      field :id do read_only true end
      field :name
      field :tag
      field :players
    end
  end

  def self.team_from_scrape(file)
    scrape = JSON.parse(File.read(file))
    regex = Regexp.new('.*?(\\d+)', Regexp::IGNORECASE)
    scrape['teams'].each do |team|
      if team['players'] && team['players'].count > 0
        team['id'] = regex.match(team['page'])[1]
        team['name'] = team['team_name']
        team['tag'] = team['name'].titleize.gsub(/[^A-Z]/, '')
        unless Team.find_by_id(team['id'])
          Team.create(team.slice('id', 'name', 'tag'))
        end
        Rails.logger.debug team['id']
        team['players'].each do |player|
          player['steam_id'] = regex.match(player['steam_profile'])[1]
          player['team_id'] = team['id']
          dbPlayer = Player.find_or_create_by(steam_id: player['steam_id'])
          dbPlayer.update(player.except('steam_profile'))
        end
      end
    end
  end

  def self.dummy #just a dummy team to pass around to keep stuff from breaking
    Team.new(name: 'No Team', tag: 'N/A').freeze
  end
end
