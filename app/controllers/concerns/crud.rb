module Concerns
  module CRUD
    extend ActiveSupport::Concern

    def crud_destroy(model, path)
    instance = model.find params[:id]
    instance.destroy!
    redirect_to path,
      flash: { successes: [%(The #{model.name.downcase}
                           "#{instance}" has been deleted.).squish] }
    end

  end
end
