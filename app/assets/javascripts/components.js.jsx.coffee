###* @jsx React.DOM ###
{div, ul, li, dl, dt, dd, b } = React.DOM
ui = if window? then window else global

# # React UI Components

ui.Execution = React.createClass
  render: ->
    data = @props.data;
    
    # list of wanted properties
    wanted = ['id', 'definition_name', 'state', 'created_at', 'updated_at'];
    
    `<li>
      <b>{data.substituted_specification_data && data.substituted_specification_data.name || '?'}</b>
      <dl>
        {wanted.map(function (want) {
          return ([
              <dt>{want}</dt>,
            <dd>{data[want] || '?'}</dd>
          ]);
        })}
      </dl>
    </li>`

ui.ExecutionsList = React.createClass
  render: ->
    executions = this.props.executions.map (execution) =>
      `<Execution data={execution} key={execution.id} />`
    
    `<ul className='executions'>
      {executions}
    </ul>`
