require_relative 'appstore_config'

module IAPServer
	class Config
		def run(options, args)
            # get the command line inputs and parse those into the vars we need...
            configs, add_name, detail, remove = get_inputs(options, args)

            if configs && configs.size > 0
                raise "路径不存在！".red unless File.exist? configs
                begin
                    json = JSON.parse(File.read(configs))
                    raise "读取的json不是一个数组！" unless json.is_a?(Array)
                    json.each do |config|
                        add_name = config['name']
                        next if add_name.nil? || add_name.empty?
                        add_config(add_name, config)
                    end
                rescue StandardError => e
                    raise "json读取错误，请检查配置文件！".red
                end
            elsif add_name
                strip_name = add_name.strip
                raise "配置名称不能为空！".red if strip_name.empty?
            	add_config(strip_name)
            else
            	# list all configs
                configs = IAPServer::AppStoreConfig.list_configs(detail)
                if configs.size > 0
                    return unless remove
                    all_num = "#{configs.size + 1}"
                    puts "#{all_num}) 删除所有配置".red
                    num = self.input("请输入前面的序号：")
                    return if num.empty? || num.to_i <= 0
                    
                    if num == all_num
                        IAPServer::AppStoreConfig.clear_all_configs
                    elsif num.to_i > 0 && configs.size > (num.to_i - 1)
                        config = configs[(num.to_i - 1)]
                        name = config['name']
                        IAPServer::AppStoreConfig.clear_config(name)
                    else
                        puts "参数输入错误，退出"
                    end
                else
                    puts "你还没有配置AppStore Connect的密钥和相关参数"
                end
            end
        end

        def get_inputs(options, args)
            configs = options.config
            add_name = options.add
            detail = options.detail
            remove = options.remove

            return configs, add_name, detail, remove
        end

        def input(message)
            print "#{message}".red
            STDIN.gets.chomp.strip
        end

        def add_config(add_name, dic={})
        	key = dic['key'] || self.input('Put AppStore key: ')
        	kid = dic['kid'] || self.input('Put AppStore key id: ')
        	iss = dic['iss'] || self.input('Put AppStore issuser id: ')
        	bid = dic['bid'] || self.input('Put AppStore bundleid: ') 
        	raise "输入的参数有误，添加失败！".red if key.empty? or kid.empty? or iss.empty? or bid.empty?

        	# fix key
        	key = key.split("\\n").join("\n") if key.include?("\\n")
        	config = {
        		'name': add_name,
        		'key': key,
        		'kid': kid,
        		'iss': iss,
        		'bid': bid
        	}
        	IAPServer::AppStoreConfig.add_config(add_name, config)
        end
	end
end