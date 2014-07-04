###* @jsx React.DOM ###
{div, ul, li, dl, dt, dd, h3 } = React.DOM
ui = if window? then window else global

fallback = "???"

# # React UI Components

ui.Execution = React.createClass
  render: ->
    wanted = ['id', 'definition_name', 'state', 'created_at', 'updated_at'];
    title = @props.data.substituted_specification_data?.name ? fallback
    
    (li {}, [
     (h3 {}, title),
     (dl {className: "dl-horizontal"}, wanted.map (item) => [
        (dt {}, item),
        (dd {}, @props.data[item] ? fallback)
       ]
     )
    ])

ui.ExecutionsList = React.createClass
  render: ->
    (ul {},
      for execution in @props.executions
        (Execution {data: execution, key: execution.id})
    )
