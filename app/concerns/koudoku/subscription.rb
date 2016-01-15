module Koudoku::Subscription
  extend ActiveSupport::Concern

  included do
    include AASM

    # We don't store these one-time use tokens, but this is what Stripe provides
    # client-side after storing the credit card information.
    attr_accessor :credit_card_token
    attr_accessor :confirm_prompt

    belongs_to :plan

    # processing states
    aasm column: :aasm_state do
      state :pending, initial: true
      state :active
      state :cancelled

      event :activate do
        transitions from: [:pending, :cancelled], to: :active
      end

      event :cancel do
        transitions from: :active, to: :cancelled
      end
    end

    # update details.
    before_save :processing!
    before_save :check_confirm_prompt

    def processing!
      # bypass processing if subscription is still yet to be confirmed
      if confirm_prompt.blank?

        # if their package level has changed ..
        if changing_plans?

          prepare_for_plan_change

          # and a customer exists in stripe ..
          if stripe_id.present?
            init_plan_change
          # when customer DOES NOT exist in stripe ..
          else
            # if a new plan has been selected
            if self.plan.present?
              create_new_customer
            else
              # This should never happen.
              self.plan_id = nil

              # Remove any plan pricing.
              self.current_price = nil
            end
          end

          self.activate if pending?

          finalize_plan_change!

        # if they're updating their credit card details.
        elsif self.credit_card_token.present?
          update_credit_card
        end

      end
    end

  end

  def init_plan_change
    # fetch the customer.
    customer = Stripe::Customer.retrieve(self.stripe_id)

    # if a new plan has been selected
    if self.plan.present?
      change_plans(customer)

    # if no plan has been selected.
    else
      cancel_plan(customer)
    end
  end

  def change_plans(customer)
    # Record the new plan pricing.
    self.current_price = self.plan.price

    prepare_for_downgrade if downgrading?
    prepare_for_upgrade if upgrading?

    # update the package level with stripe.
    customer.update_subscription(:plan => self.plan.stripe_id, :prorate => Koudoku.prorate)

    finalize_downgrade! if downgrading?
    finalize_upgrade! if upgrading?

    self.activate if cancelled?

    finalize_new_subscription! #we now except the id to be present at this point
  end

  def cancel_plan(customer)
    prepare_for_cancelation
    # Remove the current pricing.
    self.current_price = nil
    # delete the subscription.
    customer.cancel_subscription

    ## set the status of the subscription to cancelled
    self.cancel

    finalize_cancelation!
  end

  def update_credit_card
    prepare_for_card_update

    # fetch the customer.
    customer = Stripe::Customer.retrieve(self.stripe_id)
    customer.card = self.credit_card_token
    customer.save

    # update the last four based on this new card.
    self.last_four = customer.cards.retrieve(customer.default_card).last4
    self.card_type = customer.cards.retrieve(customer.default_card).brand

    finalize_card_update!
  end

  def create_new_customer

    # Record the new plan pricing.
    self.current_price = self.plan.price

    prepare_for_new_subscription
    prepare_for_upgrade

    begin

      customer_attributes = {
        description: subscription_owner_description,
        email: subscription_owner_email,
        card: credit_card_token # obtained with Stripe.js
      }

      # If the class we're being included in supports coupons ..
      if respond_to? :coupon
        if coupon.present?
          customer_attributes[:coupon] = coupon.code
        end
      end

      # create a customer at that package level.
      customer = Stripe::Customer.create(customer_attributes)

    rescue Stripe::CardError => card_error
      errors[:base] << card_error.message
      card_was_declined
      return false
    end

    # store the customer id.
    self.stripe_id = customer.id
    self.last_four = customer.cards.retrieve(customer.default_card).last4
    self.card_type = customer.cards.retrieve(customer.default_card).brand
  end


  def describe_difference(plan_to_describe)
    if plan.nil?
      if persisted?
        "Upgrade"
      else
        if Koudoku.free_trial?
          "Start Trial"
        else
          "Upgrade"
        end
      end
    else
      if plan_to_describe.is_upgrade_from?(plan)
        "Upgrade"
      else
        "Downgrade"
      end
    end
  end

  # Set a Stripe coupon code that will be used when a new Stripe customer (a.k.a. Koudoku subscription)
  # is created
  def coupon_code=(new_code)
    # @coupon_code = new_code
  end

  # Pretty sure this wouldn't conflict with anything someone would put in their model
  def subscription_owner
    # Return whatever we belong to.
    # If this object doesn't respond to 'name', please update owner_description.
    send Koudoku.subscriptions_owned_by
  end

  def subscription_owner=(owner)
    # e.g. @subscription.user = @owner
    send Koudoku.owner_assignment_sym, owner
  end

  def subscription_owner_description
    # assuming owner responds to name.
    # we should check for whether it responds to this or not.
    "#{subscription_owner.try(:name) || subscription_owner.try(:id)}"
  end

  def subscription_owner_email
    "#{subscription_owner.try(:email)}"
  end

  def changing_plans?
    plan_id_changed?
  end

  def downgrading?
    plan.present? and plan_id_was.present? and plan_id_was > self.plan_id
  end

  def upgrading?
    (plan_id_was.present? and plan_id_was < plan_id) or plan_id_was.nil?
  end

  # Template methods.
  def prepare_for_plan_change
  end

  def prepare_for_new_subscription
  end

  def prepare_for_upgrade
  end

  def prepare_for_downgrade
  end

  def prepare_for_cancelation
  end

  def prepare_for_card_update
  end

  def finalize_plan_change!
  end

  def finalize_new_subscription!
  end

  def finalize_new_customer!(customer_id, amount)
  end

  def finalize_upgrade!
  end

  def finalize_downgrade!
  end

  def finalize_cancelation!
  end

  def finalize_card_update!
  end

  def card_was_declined
  end

  # stripe web-hook callbacks.
  def payment_succeeded(amount)
  end

  def charge_failed
  end

  def charge_disputed
  end

  private

  def check_confirm_prompt
    if confirm_prompt.present?
      create_new_customer
    end
  end

end
