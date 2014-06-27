require 'spec_helper'

describe Koudoku::SubscriptionsController do
  describe 'when customer is signed in' do
    before do
      @customer = Customer.create(email: 'andrew.culver@gmail.com')
      ApplicationController.any_instance.stub(:current_customer).and_return(@customer)
    end
    it 'works' do
      get :index, use_route: 'koudoku'
    end
  end

  describe "cancelling" do
    before do
      @customer = Customer.create(email: 'andrew.culver@gmail.com')
      ApplicationController.any_instance.stub(:current_customer).and_return(@customer)

      @subscription = Subscription.create(customer_id: @customer.id, stripe_id: 'customer-id')
      # make sure they get this exact instance.
      Subscription.stub('find_by_stripe_id').and_return(@subscription)
    end

    it "redirects to show afterwards" do
      Subscription.any_instance.stub(:process_cancellation).and_return(true)
      post :cancel, use_route: 'koudoku', id: @subscription.id, owner_id: @customer.id
      response.response_code.should eq 302     
    end
  
  end
  describe 'when customer is not signed in' do
    before do
      ApplicationController.any_instance.stub(:current_customer).and_return(nil)
    end
    it 'works' do
      get :index, use_route: 'koudoku'
    end
  end
end
