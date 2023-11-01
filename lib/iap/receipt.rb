require 'net/http'
require 'json'

module IAPServer
	class Receipt
		def run(options, args)
            # get the command line inputs and parse those into the vars we need...
            receipt_data, sandbox, password = get_inputs(options, args)
			raise "必须有票据才能验证。".red if receipt_data.nil? || receipt_data.empty?

            verify(receipt_data, sandbox, password)
        end

        def get_inputs(options, args)
            receipt_data = args.first || begin
            	file = options.file || ''
            	File.read(file) if File.exist?(file) && File.file?(file)
            rescue
            	raise "文件读取失败".red
            end
            if receipt_data.nil?
            	path = self.input('Path to receipt-data file: ')
				receipt_data = File.read(path).chomp if File.exist? path
            end
            sandbox = options.sandbox
            password = options.password

            return receipt_data, sandbox, password
        end

        def input(message)
            print "#{message}".red
            STDIN.gets.chomp.strip
        end

        def request(receipt, sandbox, password)
        	uri = sandbox ? 'sandbox.itunes.apple.com' : 'buy.itunes.apple.com'
			http = Net::HTTP.new(uri, 443)
			http.use_ssl = true

			headers = {   ##定义http请求头信息
			  	'Content-Type' => 'application/json'
			}
			params = {
				'receipt-data' => "#{receipt}",
			  	'exclude-old-transactions' =>  true,
			}
			params['password'] = password unless password.nil?
			resp = http.post("/verifyReceipt", params.to_json, headers)
			resp
		end

		def verify(receipt, sandbox=false, password=nil)
			resp = request(receipt, sandbox, password)
			if resp.code == '200'
				body = JSON.parse(resp.body)
				status = body['status']
				if status == 0
					puts resp.body
				else
					error_msg = status_declare(status)
					puts "status: #{status}, #{error_msg}"
				end
			else
				puts "Code: #{resp.code}"
				puts "Message: #{resp.message}"
			end
		end

		def status_declare(status)
			error_status = {
				'21000' => 'App Store无法读取你提供的JSON数据',
				'21002' => '收据数据不符合格式',
				'21003' => '收据无法被验证',
				'21004' => '你提供的共享密钥和账户的共享密钥不一致',
				'21005' => '收据服务器当前不可用',
				'21006' => '收据是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中',
				'21007' => '收据信息是测试用（sandbox），但却被发送到产品环境中验证',
				'21008' => '收据信息是产品环境中使用，但却被发送到测试环境中验证',
			}
			error_msg = error_status[status.to_s] || "未知的status类型，请对照https://developer.apple.com/documentation/appstorereceipts/status排查"
			error_msg
		end
	end
end