require 'json'
require 'date'

file = File.read('data/input.json')
data_raw = JSON.parse(file)

cars_data = data_raw['cars']
rentals_data = data_raw['rentals']
options_list = data_raw['options']

def get_rental_days rental
  from_date = Date.parse(rental['start_date'])
  to_date = Date.parse(rental['end_date'])
  (from_date..to_date).count
end

def discount_rate days
  if days >= 1 && days < 4
    0.1
  elsif days >= 4 && days < 10
    0.3
  elsif days >= 10
    0.5
  else
    0
  end
end

def get_rate days
  rate = 0
  days.times do |day|
    rate += discount_rate(day)
  end
  rate
end

def discount_price rate, unit_price
  unit_price * rate
end

def price_by_days days, unit_price
  price = days * unit_price
  if days > 1
    rate = get_rate(days)
    price = price - discount_price(rate, unit_price)
  end

  price.to_i
end

def price_by_distance km, distance
  km * distance
end

def count_insurance_fee commission
  commission * 0.5
end

def count_assistance_fee days
  days * 100
end

def count_additionnal_fee days
  gps_price = 5 * days
  baby_seat_price = 2 * days
  return (gps_price + baby_seat_price) * 100
end

def count_additional_insurance_fee days
  10 * days * 100
end

data = { "rentals" => [] }

rentals_data.each do |rental|
  car = cars_data[0]
  rental_days = get_rental_days(rental)

  # GET price by total days with discount price
  price_by_days = price_by_days(rental_days, car['price_per_day'])

  # GET price by total distance
  price_by_km = price_by_distance(car['price_per_km'], rental['distance'])

  options = options_list.select { |f| f["rental_id"] == rental['id'] }.map { |option| option['type'] }
  options = options if !options.empty?

  # Count the additional fee
  owner_price = options.include?("additional_insurance") ? count_additional_insurance_fee(rental_days) : count_additionnal_fee(rental_days)

  total_price = price_by_days + price_by_km

  commission = total_price * 0.3
  insurance_fee = count_insurance_fee(commission)
  assistance_fee = count_assistance_fee(rental_days)
  drivy_fee = commission - insurance_fee - assistance_fee
  # Add the additional to drivy fee if have additional_insurance option
  drivy_fee = drivy_fee + owner_price if !options.empty? && options.include?("additional_insurance")
  # Recount total price if additional options not nil
  total_price = total_price + owner_price if !options.empty?

  owner_fee = total_price - insurance_fee - drivy_fee - assistance_fee

  data['rentals'] << { id: rental['id'],
                       options: options,
                       actions: [{
                                   who: 'driver',
                                   type: 'debit',
                                   amount: total_price
                                 },
                                 {
                                   who: 'owner',
                                   type: 'credit',
                                   amount: owner_fee.to_i,
                                 },
                                 {
                                   who: 'insurance',
                                   type: 'credit',
                                   amount: insurance_fee.to_i,
                                 },
                                 {
                                   who: 'assistance',
                                   type: 'credit',
                                   amount: assistance_fee.to_i,
                                 },
                                 {
                                   who: 'drivy',
                                   type: 'credit',
                                   amount: drivy_fee.to_i,
                                 }] }
end

File.open("data/output.json", "w") do |f|
  f.write(JSON.pretty_generate(data))
end