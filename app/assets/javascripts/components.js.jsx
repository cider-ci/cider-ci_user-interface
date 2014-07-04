/** @jsx React.DOM */
 
// # React UI Components

var Execution = React.createClass({
  
  render: function () {
    var data = this.props.data;
    // simple list of wanted properties
    var wanted = ['id', 'definition_name', 'state', 'created_at', 'updated_at'];
    
    return (
      <li><b>{data.substituted_specification_data && data.substituted_specification_data.name || '?'}</b>
        <dl>
          {wanted.map(function (want) {
            return ([
                <dt>{want}</dt>,
              <dd>{data[want] || '?'}</dd>
            ]);
          })}
        </dl>
      </li>
    );
  }
});

var ExecutionsList = React.createClass({
  render: function () {
    
    var executions = this.props.executions.map(function (execution) {
      return (
        <Execution data={execution} key={execution.id} />
      );
    });
    
    return (
      <ul className='executions'>
        {executions}
      </ul>
    );
  }
});
