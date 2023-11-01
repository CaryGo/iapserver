require 'pathname'
require 'json'

module IAPServer
	class AppStoreConfig
        def self.config_path
        	@config_path ||= begin
        		path = Pathname.new(File.expand_path('~/.iapserver_config'))
        		path.mkpath unless path.exist?
        		path
        	end
        	@config_path
        end

        def self.default_config
        	configs = all_configs
        	return configs.first if configs.size == 1
        	raise "你还没有配置AppStore Connect的密钥参数，执行`iapserver config -a 'xxx'`添加。".red if configs.size == 0

        	list_configs
			num = input("有多个配置，请输入序号选择合适的配置：")
			raise "序号输入有误".red if num.empty?

			raise "序号输入有误".red unless (0...configs.size) === num.to_i - 1
			return configs[(num.to_i - 1)]
        end

        def self.input(message)
            print "#{message}".red
            STDIN.gets.chomp.strip
        end

        def self.all_configs
        	config_path.children().map do |child|
        		next if File.basename(child) == '.DS_Store'
        		next unless File.file?(child)
        		JSON.parse(File.read(child))
        	end.reject(&:nil?) || []
        end

        def self.add_config(add_name, config)
			add_path = config_path + add_name
			json = config.to_json
        	File.write(add_path, json)
        end

        def self.list_configs(show_more=false)
        	configs = all_configs
        	index = 1
        	configs.each do |config|
        		name, key, kid, iss, bid = config['name'], config['key'], config['kid'], config['iss'], config['bid']
        		puts "#{index}) #{name}"
        		puts "  key: #{key}" if show_more
        		puts "  kid: #{kid}" if show_more
        		puts "  iss: #{iss}" if show_more
        		puts "  bid: #{bid}" if show_more
        		index += 1
        	end
        	return configs
        end

        def self.clear_all_configs
        	config_path.rmtree if config_path.exist?
        end

        def self.clear_config(name)
        	path = config_path + name
        	path.rmtree if path.exist?
        end
	end
end