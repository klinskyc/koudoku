require 'spec_helper'

describe Koudoku::Subscription do

	describe "cancelling a subscription" do
		before :each do
			@customer = Customer.create(email: 'andrew.culver@gmail.com')
			@subscription = Subscription.create(customer_id: @customer.id, stripe_id: 'customer-id')
			# make sure they get this exact instance.
			Subscription.stub('find_by_stripe_id').and_return(@subscription)
		end

		it "sets an active subscription to inactive" do
			@subscription.active?.should eq true
			@subscription.cancel_subscription!
			@subscription.inactive?.should eq true
			@subscription.current_price.should eq nil
			@subscription.plan_id.should eq nil
		end

		it "sets a pending_cancellation subscription to inactive" do
			@subscription.status = "pending_cancellation"
			@subscription.save

			@subscription.pending_cancellation?.should eq true
			@subscription.cancel_subscription!
			@subscription.inactive?.should eq true
			@subscription.current_price.should eq nil
			@subscription.plan_id.should eq nil
		end

	end  

end
