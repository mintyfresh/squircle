class ConversationsController < ApiController
  before_action :doorkeeper_authorize!, except: %i(index show)

  before_action :set_conversations, except: :create
  before_action :set_conversation, except: :index

  before_action :check_permission, only: :destroy, unless: :admin?

  after_action :increment_views_count, only: :show

  def index
    render json: @conversations,
           each_serializer: ConversationSerializer,
           meta: {
             page:  params[:page] || 1,
             count: params[:count] || 10,
             total: @conversations.count
           }
  end

  def show
    render json: @conversation
  end

  def create
    @conversation = Conversation.new conversation_params do |conversation|
      conversation.author = current_user
    end

    if @conversation.save
      render json: @conversation, status: :created
    else
      errors @conversation
    end
  end

  def destroy
    if @conversation.update deleted: true
      head :no_content
    else
      errors @conversation
    end
  end

private

  def conversation_params
    params.require(:conversation).permit(
      first_post_attributes: [ :character_id, :title, :body ]
    )
  end

  def set_conversations
    @conversations = Conversation.all.includes :author, :post_authors, :post_characters, :first_post, :last_post
    @conversations = @conversations.where author_id: params[:user_id] if params.key? :user_id
    @conversations = @conversations.visible unless admin?
  end

  def set_conversation
    @conversation = @conversations.find params[:id]
  end

  def check_permission
    forbid unless @conversation.author_id == current_user.id
  end

  def increment_views_count
    @conversation.increment! :views_count
  end
end
