require 'spec_helper_feature'
require 'spec_helper_feature_shared'

feature 'Result', browser: :firefox do
  scenario 'From job over task to trials' do
    sign_in_as 'normin'
    job = Job.find_by(name: 'Result-Demo')
    job.update_attributes! \
      result: job.tasks.where('result IS NOT NULL').first.result
    visit workspace_job_path(job)
    expect(find('.result-summary')).to have_content '6.45%'
    click_on 'Result'
    expect(current_path).to match %r{/workspace/jobs/[^/]+/result}
    expect(page).to have_content '6.45%'
    click_on 'Job'
    find('select#tasks_select_condition').select('All')
    click_on('Filter')
    first('a', text: 'Result Embedding Demo').click
    click_on 'Result'
    expect(current_path).to match %r{/workspace/tasks/[^/]+/result}
    expect(page).to have_content '6.45%'
    click_on 'Task'
    click_on 'main'
    click_on 'Result'
    expect(current_path).to match %r{/workspace/trials/[^/]+/result}
    expect(page).to have_content '6.45%'
  end
end
