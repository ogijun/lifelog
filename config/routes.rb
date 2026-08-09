Rails.application.routes.draw do
  root "timeline#index"

  resource :wishlist, only: :show

  # 入力フォームは種類ごとに分ける。統一フォームは「今どの種類か」という状態を持つため。
  resources :books, only: [ :new, :create ]
  resources :films, only: [ :new, :create ]
  resources :dishes, only: [ :new, :create ]
  resources :places, only: [ :new, :create ]

  resources :subjects, only: :show do
    resources :events, only: :create
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
