require "json"
require_relative 'jwttools.rb'
require_relative 'request.rb'

module IAPServer
	class NotificationHistory
		def run(options, args)
            transaction_id = args.first
            lastdays = options.lastdays
            only_failures = options.only_failures
            notification_type = options.noti_type
            notification_subtype = options.noti_subtype
            query_params = begin
            	query = ''
            	query = "paginationToken=#{options.token}" if options.token
            	query
            end
            
            raise "查询过去天数区间：[1-180]".red unless (1..180) === lastdays
            
            end_time = Time.now.utc.to_i #s
			start_time = end_time - (60 * 60 * 24 * lastdays)

			params = {
				"startDate": (start_time * 1000).to_s,
				"endDate": (end_time * 1000).to_s,
				'onlyFailures': only_failures
			}
			params['notificationType'] = notification_type unless notification_type.nil?
			params['notificationSubtype'] = notification_subtype unless notification_subtype.nil?
			params['transactionId'] = transaction_id unless transaction_id.nil?

            req = IAPServer::StoreRequest.new :use_post => true, :sandbox => options.sandbox
			resp = req.request("/inApps/v1/notifications/history/?#{query_params}", IAPServer::JWTTools.generate, params)
			validation_jwt(resp)
        end

		# 验证jwt
		def validation_jwt(resp)
			puts 'Code = ' + resp.code    ##请求状态码
			puts 'Message = ' + resp.message
			if resp.code == '200'
				body = JSON.parse(resp.body)
				notificationHistory = body["notificationHistory"]

				index = 1
				notificationHistory.each do |history|
					signedPayload = history['signedPayload']
					payload = IAPServer::JWTTools.payload(signedPayload)
					
					payload_json = JSON.parse(payload)
					signedTransactionInfo = payload_json['data']['signedTransactionInfo']
					payload_json['data']['signedTransactionInfo'] = IAPServer::JWTTools.payload(signedTransactionInfo)
					puts "#{index})".red
					puts payload_json.to_json
					index += 1
				end

				puts "还有更多的历史通知，继续查询可以传token：#{body["paginationToken"]}".red if body["hasMore"]
			end
		end
	end
end


