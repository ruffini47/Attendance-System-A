class BasesController < ApplicationController
  def new
  end
  
  def index
    @bases = Base.all
  end
end
