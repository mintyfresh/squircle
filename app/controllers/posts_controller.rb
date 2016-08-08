class PostsController < ApiController
  before_action :doorkeeper_authorize!, except: %i(index show)

  before_action :set_posts, except: :create
  before_action :set_post, except: %i(index create)

  before_action :check_permission, only: %i(update destroy), unless: :admin?
  before_action :check_character_ownership, only: %i(create update), unless: :admin?
  before_action :check_flood_limit, only: :create, unless: :admin?

  def index
    render json: @posts,
           each_serializer: PostSerializer,
           meta: {
             page:  params[:page] || 1,
             count: params[:count] || 10,
             total: @posts.count
           }
  end

  def show
    render json: @post
  end

  def create
    @post = Post.new post_params do |post|
      post.poster = current_user
    end

    if @post.save
      render json: @post, status: :created
    else
      errors @post
    end
  end

  def update
    if @post.update(post_params) { |post| post.editor = current_user }
      render json: @post
    else
      errors @post
    end
  end

  def destroy
    if @post.update deleted: true
      head :no_content
    else
      errors @post
    end
  end

private

  def post_params
    params.require(:post).permit(
      :character_id, :title, :body
    )
  end

  def set_posts
    @posts = Post.all.includes :poster, :editor, :character
    @posts = @posts.where poster_id: params[:user_id] if params.key? :user_id
    @posts = @posts.where character_id: params[:character_id] if params.key? :character_id
    @posts = @posts.visible unless current_user.try(:admin?)
  end

  def set_post
    @post = @posts.find params[:id]
  end

  def check_permission
    forbid unless @post.poster_id == current_user.id
  end

  def check_character_ownership
    unless current_user.characters.exists? id: @post.character_id
      @post.errors.add :base, 'you cannot make posts as this character'
      errors @post
    end
  end

  def check_flood_limit
    if Post.where(poster_id: current_user).exists? 'created_at > ?', 20.seconds.ago
      @post.errors.add :base, 'you can only post once every 20 seconds'
      errors @post
    end
  end
end
