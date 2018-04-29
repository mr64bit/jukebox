format = (d) ->
  if d[0].has_server == true
    return '<table class="table table-condensed" style="width: auto; margin-bottom: 0px;">' +
        "<tr><td>Server State:</td><td>#{d[0].state}</td></tr>" +
        "<tr><td>Players:</td><td>#{d[0].players}</td></tr>" +
        "<tr><td>Connect:</td><td>#{d[0].join}</td></tr>" +
        "<tr><td>STV:</td><td>#{d[0].stv}</td></tr>" +
        '</table>'
  else
    return "No Server"


$ ->
  table = $('#matches-table').DataTable(
    processing: true
    serverSide: true
    ajax: { url: $('#matches-table').data('source') }
    pagingType: "full_numbers"
    order: [[1, 'desc']]
    columns: match_columns
  )

  setInterval (-> table.ajax.reload null, false; return), 15000

  detailRows = []

  $('#matches-table tbody').on 'click', 'tr td.details-control', -> #TODO: don't colapse open rows on table refresh
    tr = $(this).closest('tr')
    row = table.row(tr)
    idx = $.inArray(tr.attr('id'), detailRows)
    if row.child.isShown()
      tr.removeClass 'details'
      row.child.hide()
      # Remove from the 'open' array
      detailRows.splice idx, 1
    else
      tr.addClass 'details'
      row.child(format(row.data())).show()
      # Add to the 'open' array
      if idx == -1
        detailRows.push tr.attr('id')
    return
  table.on 'draw', ->
    $.each detailRows, (i, id) ->
      $('#' + id + ' td.details-control').trigger 'click'
      return
    return
