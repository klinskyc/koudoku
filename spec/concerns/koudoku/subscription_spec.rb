require 'spec_helper'

describe Koudoku::Subscription do

  describe "states" do
    before :each do
      @customer = Customer.create(email: 'andrew.culver@gmail.com')

      allow_any_instance_of(Subscription).to receive(:create_new_customer).and_return true
    end

    it "creating subscription with confirm_prompt sets to pending" do
      @subscription = Subscription.create(customer_id: @customer.id, stripe_id: 'customer-id', confirm_prompt: true)
      expect(@subscription.pending?).to eq true
    end

    it "creating subscription without confirm_prompt sets to active" do
      allow_any_instance_of(Subscription).to receive(:init_plan_change).and_return true
      @subscription = Subscription.create(customer_id: @customer.id, stripe_id: 'customer-id')

      expect(@subscription.active?).to eq true
    end

    it "cancelling an active subscription sets the state to cancelled" do
      ## stub stripe operations
      allow(Stripe::Customer).to receive(:retrieve).and_return Stripe::Customer.new
      allow_any_instance_of(Stripe::Customer).to receive(:cancel_subscription).and_return true

      @subscription = Subscription.create(customer_id: @customer.id, stripe_id: 'customer-id', plan_id: nil, aasm_state: 'active')

      expect(@subscription.cancelled?).to eq true
    end
  end

end