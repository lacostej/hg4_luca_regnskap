require 'date'
require_relative 'lib/luca'

def generate_invoices_2024_data
	year = 2024
	from_month = 4
	last_month = 12

	# sections 1, 2, ....
	section_amounts = [ 7111, 4965, 5376, 4965, 7248 ]

	payment_days = 1

	invoices = []
	section_amounts.each_with_index do |amount, i|
		section_number = i + 1
		(from_month..last_month).each do |month|
			invoice_date = Date.new(year, month, 1)
			invoices << { 
				"section" => section_number,
				"amount_cents" => amount * 100,
				"invoice_date" => invoice_date.strftime('%Y-%m-%d'),
				"payment_days" => payment_days,
				"comment" => invoice_date.strftime("%B %Y")
			}
		end
	end
	invoices
end

def customer_section(customer_name)
	m = customer_name.match(/.* \(Section ([1-5])\)/)
	m[1]
end

task :check do
	# hardcoded
	sale_product_name = "felleskostnader"

	client = Luca::API.new

	# Find the product id of the first active product given the name
	products = client.products["data"]["saleProducts"]["nodes"]
	sale_product_id = products.find{|p| p['active'] == true && p['name'] == sale_product_name }['id']

	invoices_to_generate = generate_invoices_2024_data

	# Map the existing customers to their section names
	# The section number is in the customer name by convention

	existing_customers = client.customers["data"]["saleCustomers"]["nodes"]
    section_customers = existing_customers.map{|c| 
    	[customer_section(c['name']).to_i, c] 
    }.to_h

    # puts section_customers.to_json

    # Find out all generated invoices already

    # Improvement: restrict search period
	existing_invoices = client.invoices["data"]["saleInvoices"]["nodes"]
    puts existing_invoices.to_json

    # let's find out which invoices exist or miss
    invoices_to_generate.each do |invoice|
    	customer_id = section_customers[invoice['section']]['id']
    	found = existing_invoices.select do |i| 
    		i['invoiceDate'] == invoice['invoice_date'] && 
    		  i['saleCustomer']['id'] == customer_id &&
    		  i['saleInvoiceLineItems'].first['name'] == sale_product_name &&
    		  i['saleInvoiceLineItems'].first['unitPriceCents'] == invoice['amount_cents'].to_s &&
    		  i['paymentDays'] == invoice['payment_days']
    	end.first

    	found_text = "#{found['id']}, draft: #{found['draft']}, finalized: #{found['finalized']}, sent_at: #{found['sentAt']}" if found
    	puts "Searching for #{invoice['section']} on #{invoice['invoice_date']} Found: #{found_text}"

    	if found && found['draft'] == true
    		puts "= Finalizing invoice #{found}"
    		puts client.finalize_invoice(invoice_id: found['id']).to_json
    		puts client.send_invoice_email(invoice_id: found['id'], email: section_customers[invoice['section']]['email']).to_json
    		#exit -1
    	end

    	if found && found['finalized'] == true && found['sentAt'].nil?
    		puts "Sending not sent invoice #{found['id']}"
    		exit -1 # detection logic not yet checked
			# puts client.send_invoice_email(invoice_id: found['id'], email: section_customers[invoice['section']]['email']).to_json
    	end

    	unless found
    		puts "= Creating invoice as draft"
    		response = client.create_draft_invoice(
    			customer_id: customer_id,
    			invoice_date: invoice['invoice_date'],
				payment_days: invoice['payment_days'],
				sale_product_id: sale_product_id,
				quantity: 1,
				unit_price_cents: invoice['amount_cents'].to_s,
				comment: invoice['comment'])
    		puts response.to_json
    	end
    end

end

task :luca_playground do
	client = Luca::API.new
	json = client.invoices
    puts json.to_json
end