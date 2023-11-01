require 'net/http'
require 'json'

module IAPServer
	class StoreRequest
		def initialize(use_post: false, sandbox: false)
			@use_post = use_post
			@sandbox = sandbox
		end

		def request(path, token, params={})
			http = Net::HTTP.new('api.storekit.itunes.apple.com', 443)
	        if @sandbox
	            http = Net::HTTP.new('api.storekit-sandbox.itunes.apple.com', 443)
	        end
			http.use_ssl = true

			headers = {   ##定义http请求头信息
			  'Authorization' => "Bearer #{token}",
			  'Content-Type' => 'application/json'
			}
			if @use_post
				resp = http.post(path, params.to_json, headers)
			else
				resp = http.get(path, headers)
			end
			resp
		end
	end
end

