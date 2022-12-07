class BooksController < ApplicationController
  before_action :intialize_session
  before_action :increment_visit_count
  before_action :load_cart
  before_action :authenticate_user!, :except => [:index, :show]

  def index
    if current_user
      @books_by_user = Book.books_by_user(current_user.id)
      @book = Book.all
      render :index
    else 
      @book = Book.all
    end
  end

  def new 
    @book = Book.new
    render :sell
  end
  
  def create
    @book = Book.new(book_params)
    @book.user_id = current_user.id
    if @book.save
      flash[:notice] = "Product successfully added!"
      redirect_to books_path
    else
      render :sell, status: :unprocessable_entity
    end

  end

  def show
    @book = Book.find(params[:id])
    user = User.find(@book.user_id)
    @user_username = user.username
    render :show
  end

  def update
    @book = Book.find(params[:id])
    if @book.update!(book_params)
      render status: 200, json: {
        message: "This book has been updated successfully."
      }
    end
  end

  def destroy
    @book = Book.find(params[:id])
    @book.destroy
    flash[:notice] = "Book has been deleted."
    redirect_to root_path
  end

  def add_to_cart 
    id = params[:id].to_i 
    session[:cart] << id unless session[:cart].include?(id)
    redirect_to root_path
  end 

  def remove_from_cart 
    id = params[:id].to_i 
    session[:cart].delete(id)
    redirect_to root_path
  end

  def checkout_cart 
    for i in session[:cart] 
      while session[:cart].length > 0
        book = Book.find(i)
        book_user_id = book.user_id 
        user = User.find(book_user_id)
        
        new_balance = user.wallet_balance += book.price 

        user.update({:wallet_balance => new_balance})
        book.update({:sold => true})  
        session[:cart].pop(i)
      end
    end 
    session[:cart].clear
    redirect_to root_path
  end 
  
  private

  def intialize_session 
    session[:visit_count] ||= 0 
    session[:cart] ||= []
  end

  def load_cart
    @cart = Book.find(session[:cart])
  end

  def increment_visit_count 
    session[:visit_count] += 1 
    @visit_count = session[:visit_count] 
  end

  def book_params
    params.require(:book).permit(:title, :author, :genre, :price, :user_id)
  end

  def json_response(object, status = 401)
    render json: object, status: status
  end

end