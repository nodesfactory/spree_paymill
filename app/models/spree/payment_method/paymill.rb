# encoding: UTF-8
require 'paymill'

module Spree
  class PaymentMethod::Paymill < Spree::PaymentMethod
    preference :private_key, :string
    preference :public_key, :string
    
    attr_accessible :preferred_private_key, :preferred_public_key
    
    def payment_source_class
      CreditCard
    end
    
    def authorize(money, credit_card, options = {})
      init_data
      order = Spree::Order.find_by_number(options[:order_id])
      
      timestamp = Time.now
      
      payment = ::Paymill::Payment.create(
        id: "pay_#{options[:order_id]}",
        card_type: credit_card.spree_cc_type, 
        token: order.payment.response_code,
        country: nil, 
        expire_month: credit_card.month, 
        expire_year: credit_card.year,
        card_holder: nil,
        last4: credit_card.display_number[15..18], 
        created_at: timestamp,
        updated_at: timestamp
      )
      
      unless payment.id.nil?
        order.payment.response_code = payment.id
        order.payment.save!
      
        transaction = ::Paymill::Transaction.create(
          amount: money,
          payment: payment.id,
          client: options[:customer],
          currency: "EUR"
        )
        
        unless transaction.id.nil?
          ActiveMerchant::Billing::Response.new(true, 'Paymill transaction successful', {}, :authorization => transaction.id)
        else
          ActiveMerchant::Billing::Response.new(false, 'Paymill transaction unsuccessful')
        end
      else
        ActiveMerchant::Billing::Response.new(false, 'Paymill payment unsuccessful')
      end
    end
    
    private
    def init_data
      ::Paymill.api_key = preferred_private_key
    end
  end
end
