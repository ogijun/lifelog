class WishlistsController < ApplicationController
  def show
    @kind = params[:kind].presence
    @suggestions = Wishlist.suggestions(on: Date.current, kind: @kind)
  end
end
