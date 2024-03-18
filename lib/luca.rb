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

		private

		def headers
			{
				'Authorization' => "Bearer #{@access_token}",
				'Content-Type' => 'application/json'
			}
		end
	end
end