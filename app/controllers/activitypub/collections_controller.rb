# frozen_string_literal: true

class ActivityPub::CollectionsController < ActivityPub::BaseController
  include SignatureVerification
  include AccountOwnedConcern

  before_action :require_signature!, if: :authorized_fetch_mode?
  before_action :set_size
  before_action :set_statuses
  before_action :set_cache_headers

  def show
    expires_in 3.minutes, public: public_fetch_mode?
    render_with_cache json: collection_presenter, content_type: 'application/activity+json', serializer: ActivityPub::CollectionSerializer, adapter: ActivityPub::Adapter, skip_activities: true
  end

  private

  def set_statuses
    @statuses = scope_for_collection
    @statuses = cache_collection(@statuses, Status)
  end

  def set_size
    case params[:id]
    when 'featured'
      @account.pinned_statuses.count
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def scope_for_collection
    case params[:id]
    when 'featured'
      @account.statuses.permitted_for(@account, signed_request_account).tap do |scope|
        scope.merge!(@account.pinned_statuses)
      end
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def collection_presenter
    ActivityPub::CollectionPresenter.new(
      id: account_collection_url(@account, params[:id]),
      type: :ordered,
      size: @size,
      items: @statuses
    )
  end
end
