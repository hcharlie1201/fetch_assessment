# app/controllers/receipts_controller.rb
require 'securerandom'
require 'date'
require 'time'

class ReceiptsController < ApplicationController
  @@receipts = {}

  def process_receipt
    begin
      receipt_data = JSON.parse(request.body.read)

      unless valid_receipt?(receipt_data)
        render json: { error: "The receipt is invalid. Please verify input." }, status: :bad_request
        return
      end

      receipt_id = SecureRandom.uuid
      points = calculate_points(receipt_data)

      @@receipts[receipt_id] = {
        receipt: receipt_data,
        points: points
      }

      render json: { id: receipt_id }
    rescue JSON::ParserError
      render json: { error: "The receipt is invalid. Please verify input." }, status: :bad_request
    end
  end

  def get_points
    receipt_id = params[:id]

    if @@receipts.key?(receipt_id)
      render json: { points: @@receipts[receipt_id][:points] }
    else
      render json: { error: "No receipt found for that ID." }, status: :not_found
    end
  end

  private

  def valid_receipt?(receipt)
    # Required fields
    required_fields = %w[retailer purchaseDate purchaseTime items total]
    return false unless required_fields.all? { |field| receipt.key?(field) }
    return false unless receipt['retailer'].is_a?(String) && receipt['retailer'].match?(/^[\w\s\-&]+$/)

    # Validate purchaseDate
    begin
      Date.parse(receipt['purchaseDate'])
      Time.parse(receipt['purchaseTime'])
    rescue ArgumentError
      return false
    end

    # Validate items array
    return false unless receipt['items'].is_a?(Array) && receipt['items'].length >= 1

    receipt['items'].each do |item|
      return false unless item.is_a?(Hash)
      return false unless item.key?('shortDescription') && item.key?('price')
      return false unless item['shortDescription'].is_a?(String) && item['shortDescription'].match?(/^[\w\s\-]+$/)
      return false unless item['price'].is_a?(String) && item['price'].match?(/^\d+\.\d{2}$/)
    end

    # Validate total
    return false unless receipt['total'].is_a?(String) && receipt['total'].match?(/^\d+\.\d{2}$/)

    true
  end

  def calculate_points(receipt)
    points = 0

    # One point for every alphanumeric character in the retailer name
    points += receipt['retailer'].gsub(/[^a-zA-Z0-9]/, '').length

    # 50 points if the total is a round dollar amount with no cents
    points += 50 if receipt['total']&.include?('.')

    # 25 points if the total is a multiple of 0.25
    total_cents = (receipt['total'].to_f * 100)
    points += 25 if total_cents % 25 == 0.0

    # 5 points for every two items on the receipt
    points += (receipt['items'].length / 2) * 5

    # If the trimmed length of the item description is a multiple of 3,
    # multiply the price by 0.2 and round up to the nearest integer
    receipt['items'].each do |item|
      trimmed_length = item['shortDescription'].strip.length
      if trimmed_length % 3 == 0
        points += (item['price'].to_f * 0.2).ceil
      end
    end

    # 6 points if the day in the purchase date is odd
    purchase_date = Date.parse(receipt['purchaseDate'])
    points += 6 if purchase_date.day.odd?

    # 10 points if the time of purchase is after 2:00pm and before 4:00pm
    purchase_time = Time.parse(receipt['purchaseTime'])
    if purchase_time.hour >= 14 && purchase_time.hour < 16
      points += 10
    end

    points
  end
end