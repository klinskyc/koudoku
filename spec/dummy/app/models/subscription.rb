class Subscription < ActiveRecord::Base
  include Koudoku::Subscription

  # attr_accessible :customer_id, :stripe_id

  belongs_to :customer
  belongs_to :coupon

end
