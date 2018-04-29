class MatchDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::Kaminari
  include AjaxDatatablesRailsTableHelper

  def table_manager
    @table_manager ||= TableManager.new([
                                              { role: 'guest',
                                                columns: [{
                                                              header_name: '',
                                                              source: lambda{|record| if record.server
                                                                                        server = record.server
                                                                                        return { has_server: true,
                                                                                                 state: server.state.titleize,
                                                                                                 stv: @view.link_to(server.stv_string, "steam://connect/#{server.real_address}:#{server.stv_port}"),
                                                                                                 join: "Not available for guests. (#{@view.login_logout})",
                                                                                                 players: server.num_players }
                                                                                      else
                                                                                        return { has_server: false }
                                                                                      end},
                                                              orderable: false,
                                                              searchable: false,
                                                              javascript: '"class": "details-control", "defaultContent": "", "data": null',

                                                          },
                                                          {
                                                              header_name: 'ID',
                                                              db_column: 'Match.id',
                                                              source: lambda{|record| record.id}
                                                          },
                                                          {
                                                              header_name: 'Code',
                                                              db_column: 'Match.match_code',
                                                              source: lambda{|record| record.match_code}
                                                          },
                                                          {
                                                              header_name: 'State',
                                                              db_column: 'Match.state',
                                                              source: lambda{|record| record.state.titleize}
                                                          },
                                                          {
                                                              header_name: 'Time (PST)',
                                                              source: lambda{|record| record.starts_at.in_time_zone('Pacific Time (US & Canada)').to_formatted_s(:short)},
                                                              db_column: 'Match.starts_at'
                                                          },
                                                          {
                                                              header_name: 'Maps',
                                                              source: lambda{|record| record.match_maps.sort_by{|map| map.part_of_set}.map{|map| map.map}.join('<br>') },
                                                              db_column: 'MatchMap.map'
                                                          },
                                                          {
                                                              header_name: 'Scores',
                                                              source: lambda{|record| record.short_scores_logs.join('<br>')},
                                                              searchable: false,
                                                              orderable: false
                                                          },
                                                          {
                                                              header_name: 'Region',
                                                              db_column: 'Match.region',
                                                              source: lambda{|record| record.region.upcase}
                                                          }
                                                       ]
                                              },
                                              { role: 'player',
                                                columns: [{
                                                              header_name: '',
                                                              source: lambda{|record| if record.server
                                                                                        server = record.server
                                                                                        return { has_server: true,
                                                                                                 state: server.state.titleize,
                                                                                                 stv: @view.link_to(server.stv_string, "steam://connect/#{server.real_address}:#{server.stv_port}"),
                                                                                                 join: @view.link_to(server.connect_string, "steam://connect/#{server.real_address}:#{server.listen_port}/#{server.sv_password}"),
                                                                                                 players: server.num_players }
                                                                                      else
                                                                                        return { has_server: false }
                                                                                      end},
                                                              orderable: false,
                                                              searchable: false,
                                                              javascript: '"class": "details-control", "defaultContent": "", "data": null',

                                                          },
                                                          {
                                                              header_name: 'ID',
                                                              db_column: 'Match.id',
                                                              source: lambda{|record| record.id}
                                                          },
                                                          {
                                                              header_name: 'Code',
                                                              db_column: 'Match.match_code',
                                                              source: lambda{|record| record.match_code}
                                                          },
                                                          {
                                                              header_name: 'State',
                                                              db_column: 'Match.state',
                                                              source: lambda{|record| record.state.titleize}
                                                          },
                                                          {
                                                              header_name: 'Time (PST)',
                                                              source: lambda{|record| record.starts_at.in_time_zone('Pacific Time (US & Canada)').to_formatted_s(:short)},
                                                              db_column: 'Match.starts_at'
                                                          },
                                                          {
                                                              header_name: 'Maps',
                                                              source: lambda{|record| record.match_maps.sort_by{|map| map.part_of_set}.map{|map| map.map}.join('<br>') },
                                                              db_column: 'MatchMap.map'
                                                          },
                                                          {
                                                              header_name: 'Scores',
                                                              source: lambda{|record| record.short_scores_logs.join('<br>')},
                                                              searchable: false,
                                                              orderable: false
                                                          },
                                                          {
                                                              header_name: 'Region',
                                                              db_column: 'Match.region',
                                                              source: lambda{|record| record.region.upcase}
                                                          }
                                                      ]
                                              }])
  end

  def sortable_columns
    # Declare strings in this format: ModelName.column_name
    @sortable_columns ||= table_manager.table_for(@view.viewing_as).sortable
  end

  def searchable_columns
    # Declare strings in this format: ModelName.column_name
    @searchable_columns ||= table_manager.table_for(@view.viewing_as).searchable
  end

  private

  def data
    records.map do |record|
      decorated = record.decorate
      next table_manager.table_for(@view.viewing_as).record_columns(decorated)
    end
  end

  def get_raw_records
    Match.includes(:match_maps, :server).joins(:matches_teams).references(:match_maps).where(tournament_id: Settings::CURRENT_TOURNAMENT).where.not(matches_teams: {match_id: nil})
  end
end
