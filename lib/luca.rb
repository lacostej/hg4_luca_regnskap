require 'httparty'
require 'oauth2'
require 'fileutils'

module Luca
	class API
		include HTTParty
		base_uri 'https://go.lucaregnskap.no/api/v1/graphql'
		#debug_output

		def initialize
			require 'dotenv'
			@env = Dotenv.load("secrets.env")
			# personal token
			@access_token = @env['personal_token']
		end

		#def login(username, password)
		def authenticate
			uri = 'https://authentication.wolt.com/v1/wauth2/access_token'
			refresh_token = 'f283d94c-adcc-4f98-bb0f-8ba0179f7295'

			form = {
				grant_type: "refresh_token",
				refresh_token: refresh_token
			}

			response = self.class.post(uri, headers: {
				'Accept' => 'application/json, text/plain, */*',
				'Accept-Language' => 'en-US,en;q=0.5',
				'Connection' => 'keep-alive',
				'Content-Type' => 'application/x-www-form-urlencoded',
			}, body: form)

			json = JSON.parse(response.body)
			@access_token = json['access_token']
			@refresh_token = json['refresh_token']
		end

		def customers
			body = {
				'query' => 'query { saleCustomers { nodes { id , active, comment, email, id, name } } }',
			}
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end

		def invoices
			body = {
				'query' => 'query { saleInvoices { nodes { id , draft , finalized, invoiceDate, invoiceNumber, paymentDays, sentAt, saleCustomer { id, email, name}, saleInvoiceLineItems {id, name, quantity, unit, unitPriceCents, saleProduct{id, name}} } } }',
			}
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end

		def products
			body = {
				'query' => 'query { saleProducts { nodes { id , name , active } } }',
			}
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end

		def create_draft_invoice(
			customer_id: ,
			invoice_date: ,
			payment_days: ,
			sale_product_id: ,
			quantity: ,
			unit_price_cents: ,
			comment: )
			# generate the mutation string
			
			query = "mutation SaleInvoiceCreate($saleInvoiceInputVariable: SaleInvoiceInput!) { saleInvoiceCreate(saleInvoice: $saleInvoiceInputVariable) { id , draft , finalized, invoiceDate, invoiceNumber, paymentDays, saleCustomer { id, email, name} } }"

			variables = {
				"saleInvoiceInputVariable" => {
					"saleCustomer" => {
						"id"=> customer_id
					},
					"invoiceDate" => invoice_date,
					"paymentDays" =>  payment_days,
					"invoiceType" =>  "DRAFT",
					"saleInvoiceLineItems" =>  {
						"saleProductId" =>  sale_product_id,
						"quantity" => quantity,
						"unitPriceCents" => unit_price_cents
					},
					"comment" => comment
				}
			}

			body = {
					'query' => query,
					'variables' => variables
			}
			# puts body.to_json
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end

		def finalize_invoice(invoice_id: )
			query = "mutation SaleInvoiceUpdate($saleInvoiceIDVariable: ID!, $saleInvoiceInputVariable: SaleInvoiceInput!) { saleInvoiceUpdate(id: $saleInvoiceIDVariable, saleInvoice: $saleInvoiceInputVariable) { id , draft , finalized, invoiceDate, invoiceNumber, paymentDays, saleCustomer { id, email, name} } }"
			variables = {
				"saleInvoiceIDVariable" => invoice_id,
				"saleInvoiceInputVariable" => {
					"invoiceType" => "INVOICE"
				}
			}

			body = {
					'query' => query,
					'variables' => variables
			}
			# puts body.to_json
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end

		def send_invoice_email(invoice_id: , email: )
			query = "mutation SaleInvoiceSend($saleInvoiceIDVariable: ID!, $saleInvoiceEmailVariable: String, $sendMethodVariable: SaleSendMethod!) { saleInvoiceSend(id: $saleInvoiceIDVariable, sendMethod: $sendMethodVariable, email: $saleInvoiceEmailVariable) { id , draft , finalized, invoiceDate, invoiceNumber, paymentDays, saleCustomer { id, email, name} } }"
			variables = {
				"saleInvoiceIDVariable" => invoice_id,
				"sendMethodVariable" => "EMAIL",
				"saleInvoiceEmailVariable" => email
			}

			body = {
					'query' => query,
					'variables' => variables
			}
			puts body.to_json
			response = self.class.post(self.class.base_uri, body: body.to_json, headers: headers)
			json = JSON.parse(response.body)
		end
		def timestr(time)
			Time.parse(time).iso8601(3)
		end

# external code, for pagination example
# /v1/merchant-admin/venues/605e20a324012913ebbb649d/completed_purchases?end_time=2021-10-03T00:00:00.000+02:00&limit=40&start_time=2021-10-02T00:00:00.000+02:00
=begin
	  	def purchases(venue_id:, start_time:, end_time:, limit: 40)
			uri = "/merchant-admin/venues/#{venue_id}/completed_purchases"
			params = {
				start_time: timestr(start_time),
				end_time: timestr(end_time),
				limit: limit
			}
			purchases = []
			loop do
				response = self.class.get(uri, headers: headers, query: params)
				json = JSON.parse(response.body)
				#puts json
				purchases += json['data']['purchases']

				cursor_next = json['metadata']['next']
				break if cursor_next.nil?

				params['cursor'] = cursor_next
			end

			purchases
		end
=end

		private

		def headers
			{
				'Authorization' => "Bearer #{@access_token}",
				'Content-Type' => 'application/json'
			}
		end

		def ua
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:92.0) Gecko/20100101 Firefox/92.0'
		end		
	end
end