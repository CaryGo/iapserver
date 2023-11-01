require "json"
require_relative './jwttools.rb'
require_relative './request.rb'

module IAPServer
	class Order
		def run(options, args)
            # get the command line inputs and parse those into the vars we need...
            order_num = get_inputs(options, args)
            raise "必须有订单号。".red if order_num.nil? || order_num.empty?

            req = IAPServer::StoreRequest.new
			resp = req.request("/inApps/v1/lookup/#{order_num}", IAPServer::JWTTools.generate)
			validation_jwt(resp)
        end

        def get_inputs(options, args)
            order_num = args.first || self.input('put order-num: ')

            return order_num
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

				status = body["status"]
				if !status.nil? && status == 0
					jwt_list = body["signedTransactions"]
					jwt_token = jwt_list[0]

					if IAPServer::JWTTools.good_signature(jwt_token)
						payload = IAPServer::JWTTools.payload(jwt_token)
						puts "Payload：" + payload

						result = JSON.parse(payload)
						purchaseDate = result["purchaseDate"]
						puts "支付时间：#{Time.at(purchaseDate/1000)}"
					else
						puts "JWT 验证失败"
					end
				elsif status == 1
					puts "status：#{status}，查询失败。可能的原因：jwt签名正确，bundleid不一致"
				else
					puts "status：#{status}，请排查错误原因"
				end
			end
		end
	end
end


