require "json"
require_relative 'jwttools.rb'
require_relative 'request.rb'

module IAPServer
	class Transaction
		def run(options, args)
            # get the command line inputs and parse those into the vars we need...
            transaction_id = get_inputs(options, args)
            if transaction_id.nil? || transaction_id.empty?
            	raise "必须有transaction id。".red
            end
            
			req = IAPServer::StoreRequest.new :sandbox => options.sandbox
			resp = req.request("/inApps/v1/transactions/#{transaction_id}", IAPServer::JWTTools.generate)
			validation_jwt(resp)
        end

        def get_inputs(options, args)
            transaction_id = args.first || self.input('put transaction id: ')
            return transaction_id
        end

        def input(message)
            print "#{message}".red
            STDIN.gets.chomp.strip
        end

		# 验证jwt
		def validation_jwt(resp)
			puts 'Code = ' + resp.code    ##请求状态码
			puts 'Message = ' + resp.message
			if resp.code == '200'
				body = JSON.parse(resp.body)

				jwt_list = body["signedTransactions"]
				if !jwt_list.nil? && jwt_list.count > 0
					jwt_token = jwt_list[0]

					if IAPServer::JWTTools.good_signature(jwt_token)
						payload = IAPServer::JWTTools.payload(jwt_token)
						puts "Payload：" + payload
					else
						puts "JWT 验证失败"
					end
				else
					puts '没有查询到交易信息'
				end
			end
		end
	end
end


