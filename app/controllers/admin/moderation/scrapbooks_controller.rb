class Admin::Moderation::ScrapbooksController < Admin::AuthenticatedAdminController
  INDEXES = [:index, :moderated, :reported]

  before_action :store_scrapbook_index_path, only: INDEXES
  before_action :assign_scrapbook, except: INDEXES

  def index
    @items = Scrapbook.unmoderated
  end

  def moderated
    @items = Scrapbook.moderated.by_last_moderated
    render :index
  end

  def reported
    @items = Scrapbook.reported.by_first_moderated
    render :index
  end

  def show
    @memories = Kaminari.paginate_array(@scrapbook.ordered_memories).page(params[:page])
  end

  def approve
    if @scrapbook.approve!(current_user)
      message = {notice: 'Scrapbook approved'}
    else
      message = {alert: 'Could not approve scrapbook'}
    end
    redirect_to admin_moderation_scrapbooks_path, message
  end

  def reject
    if @scrapbook.reject!(current_user, params[:reason])
      message = {notice: 'Scrapbook rejected'}
    else
      message = {alert: 'Could not reject scrapbook'}
    end
    redirect_to admin_moderation_scrapbooks_path, message
  end

  def unmoderate
    if @scrapbook.unmoderate!(current_user)
      message = {notice: 'Scrapbook unmoderated'}
    else
      message = {alert: 'Could not unmoderate scrapbook'}
    end
    redirect_to admin_moderation_scrapbooks_path, message
  end

  private

  def assign_scrapbook
    @scrapbook = Scrapbook.find(params[:id])
  end
end