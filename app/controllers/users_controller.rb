class UsersController < ApplicationController
  def new
    @user = User.new
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
      #redirect_to user_url(@user.id) でも同じ
      #redirect_to user_url(@user) でも同じ
    else
      render :new
    end
  end
  
  private
  
    
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

end