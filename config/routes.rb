# frozen_string_literal: true

SwarmpodGem::Engine.routes.draw do
  root to: "dashboard#index"

  namespace :api, defaults: { format: :json } do
    get  "state",      to: "state#show"
    get  "tabs",       to: "tabs#index"
    post "tab/:id",    to: "tabs#activate"
    post "message",    to: "messages#create"
  end
end
