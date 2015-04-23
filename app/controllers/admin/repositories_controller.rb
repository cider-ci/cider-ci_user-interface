#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Admin::RepositoriesController < AdminController
  include Concerns::CRUD

  def permited_repository_params(params)
    if params[:repository]
      params[:repository].permit(:name, :origin_uri, 
                                 :git_fetch_and_update_interval,
                                 :git_update_interval, :public_view_permission)
    end
  end

  def create
    @repository = Repository.create! permited_repository_params(params)
    redirect_to \
      admin_repositories_path,
      flash: {
        successes:
        ['The repository has been created. It will be initialized in the background.'] }
  end

  def destroy
    crud_destroy Repository, admin_repositories_path
  end

  def edit
    @repository = Repository.find(params[:id])
  end

  def index
    @repositories = Repository.page(params[:page])
  end

  def new
    @repository = Repository.new permited_repository_params(params)
  end

  def update
    @repository = Repository.find(params[:id])
    @repository.update_attributes! permited_repository_params(params)
    redirect_to \
      admin_repository_path(@repository),
      flash: { successes: ['The repository has been updated.'] }
  end

  def show
    @repository = Repository.find(params[:id])
  end

end
