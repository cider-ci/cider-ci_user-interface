#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Admin::ExecutorsController < AdminController
  include Concerns::CRUD

  def create
    @executor = Executor.create! processed_params
    redirect_to admin_executors_path,
                flash: {
                  successes:
                  [%( The new executor "#{@executor}" has been created.)] }
  end

  def destroy
    crud_destroy Executor, admin_executors_path
  end

  def edit
    @executor = Executor.find params[:id]
  end

  def index
    @executors = ExecutorWithLoad.page(params[:page])
  end

  def new
    @executor = Executor.new processed_params
  end

  def update
      @executor =  Executor.find params[:id]
      @executor.update_attributes! processed_params
      redirect_to admin_executors_path,
                  flash: { successes: ['The executor has been updated.'] }
  end

  def processed_params
    traits = params[:executor].try(:[], :traits).try(:split, ',')
    .try(:map) { |s|s.strip }.try(:sort).try(:uniq)
    params[:executor].try(:permit, :name, :host, :port, :ssl, :server_overwrite,
                          :server_host, :server_port, :server_ssl, :max_load,
                          :enabled, :traits) \
                      .try(:merge, traits: traits)
  end

end
