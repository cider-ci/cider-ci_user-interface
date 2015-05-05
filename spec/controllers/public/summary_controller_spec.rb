require 'spec_helper'

describe ::Public::SummaryController, type: :controller do

  context ' a public viewable job via personas data' do
    before :all do
      PgTasks.truncate_tables
      PgTasks.data_restore Rails.root.join('db', 'personas.pgbin')
      Repository.first.update_attributes! public_view_permission: true
    end

    describe 'response codes' do

      describe 'get exiting repo/branch/job ' do
        before :each do
          get :show, branch_name: 'master',
                     repository_name: 'Cider-CI Bash Demo Project',
                     job_names: 'Tests'
        end
        it 'responses with 200' do
          assert_response 200
        end
      end

      describe 'get non exiting repo/branch ' do
        before :each do
          get :show, branch_name: 'NOBRANCH',
                     repository_name: 'Cider-CI Bash Demo Project',
                     job_names: 'Tests'
        end
        it 'responses with 404' do
          assert_response 404
        end
      end

      describe 'get non exiting repo/branch with respond_with_200 parameter' do
        before :each do
          get :show, branch_name: 'NOBRANCH',
                     repository_name: 'Cider-CI Bash Demo Project',
                     job_names: 'Tests', respond_with_200: ''
        end
        it 'responses with 200' do
          assert_response 200
        end
      end

      context 'non public repo' do

        before :each do
          Repository.first.update_attributes! public_view_permission: false
        end

        describe 'get exiting repo/branch/job ' do
          before :each do
            get :show, branch_name: 'master',
                       repository_name: 'Cider-CI Bash Demo Project',
                       job_names: 'Tests'
          end
          describe 'get repo/branch/job ' do
            it 'responds with 403' do
              assert_response 403
            end
          end
        end

        describe 'get exiting repo/branch/job with respond_with_200 parameter' do
          before :each do
            get :show, branch_name: 'master',
                       repository_name: 'Cider-CI Bash Demo Project',
                       job_names: 'Tests',
                       respond_with_200: ''
          end
          describe 'get repo/branch/job ' do
            it 'responds with 200' do
              assert_response 200
            end
          end
        end

      end

    end

  end

end
