###* @jsx React.DOM ###
{div, ul, li, dl, dt, dd, h3, table, thead, tbody, tr, td } = React.DOM
c = if window? then window else global

# # React UI Components

# ## Config
fallback = "???"
ciderColormap = {
  pending: 'info'
  failed: 'danger'
  success: 'success'
}

###
TODO:
- use classList helper
- use mixins
###

c.ExecutionsList = React.createClass
  render: ->
    (table {className: "table executions-table"}, [
      (thead {}),
      (tbody {}, @props.executions.map (execution) ->
        (ExecutionRow {data:execution}))
    ])
    
    (table {}, [
      
    ])


c.ExecutionRow = React.createClass
  render: -> 
    colorClass = ciderColormap[@props.data.state]
    
    (tr {className: "execution "+colorClass}, [
      @transferPropsTo(ExecutionOverview {}),
      @transferPropsTo(ExecutionStats {}),
      @transferPropsTo(ExecutionTimestamp {}),
      @transferPropsTo(ExecutionRepositories {}),
      @transferPropsTo(ExecutionTags {}),
      @transferPropsTo(ExecutionBranches {}),
      @transferPropsTo(ExecutionCommits {}),
    ])
    
c.ExecutionOverview = React.createClass
  render: ->
    labelClass = "label label-#{@props.data.state}"
    iconClass = "icon icon-#{@props.data.state}"
    url = "/cider-ci/workspace/executions/#{@props.data.id}"
    
    (`<td className="execution">
      <span className="nowrap">
        <span>
          <a className={labelClass} href={url}>
          <i className={iconClass}></i>
          </a>
        </span>
        <a href={url}>
          <span style={{'margin-left': '0.5em'}}>
            {this.props.data.definition_name}
          </span>
        </a>
      </span>
    </td>`)

c.ExecutionStats = React.createClass
  render: ->
    
    state = @props.data.state
    stats = @props.data.execution_stat
    fraction =
      failed: stats.failed/stats.total*100
      success: stats.success/stats.total*100
    
    (`<td className="stats">
      <div className="progress" style={{'margin-bottom': '0.2em'}}>
        <div className="progress-bar progress-bar-danger" style={{'width': (fraction.failed)+'%'}} />
        <div className="progress-bar progress-bar-success" style={{'width': (fraction.success)+'%'}} />
        {state == 'success' ? stats.success : null}
      </div>
      <span className="nowrap">
        {state == 'failed' ? stats.success+' / '+stats.total : null}
      </span>
    </td>`)

c.ExecutionTimestamp = React.createClass
  render: ->
    timestamp = @props.data.created_at
    
    (`<td className="created-at">
      <span className="humanize-timestamp" data-at={timestamp}>
        {timestamp}
      </span>
    </td>`)

c.ExecutionRepositories = React.createClass
  render: ->
    repos = @props.data.repositories.map (repo) =>
      `<li>
        <span className="nowrap">
          <strong className="nowrap">
            {repo.name}
          </strong>
          </span>
        </li>`
    
    (`<td className="repositories">
      <ul className="list-unstyled">
        {repos}
      </ul>
    </td>`)

c.ExecutionTags = React.createClass
  render: ->
    tags = @props.data.tags.map (tag) =>
      (`<li>
        <a className="label label-default" 
           href={'executions?execution_tags=%2C+'+tag.tag}> {/* this is a hack - we can't use rails' path helpers… */}
          {tag.tag}
        </a>
      </li>`)
    
    (`<td className="tags">
      <div className="tags">
        <ul className="list-inline">
          {tags}
        </ul>
      </div>
    </td>`)

c.ExecutionBranches = React.createClass
  render: ->
    console.log @props.data

    (`<td className="branches">
      <ul className="list-unstyled">
        <li>
          <strong>TODO</strong>
        </li>
      </ul>
    </td>`)

c.ExecutionCommits = React.createClass
  render: ->
    commits = this.props.data.commits.map (commit) =>
      name= commit.committer_email.replace(/@.*/,'').slice(0,15)
      message= if (commit.subject.length >= 30)
          commit.subject.slice(0,29)+'…'
        else
          commit.subject
        
      (`<li>
        {name+': '}
        <em>
          {message}
        </em>
      </li>`)
    
    (`<td className="commits">
      <ul className="list-unstyled">
        {commits}
      </ul>
    </td>`)

