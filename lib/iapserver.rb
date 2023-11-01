require 'rubygems'
require 'commander/import'

require 'colored2'
require 'version'

require 'iap/receipt'
require 'iap/order'
require 'iap/config'
require 'iap/history'
require 'iap/transaction'
require 'iap/subscription'
require 'iap/refund'
require 'iap/notification_history'

module IAPServer
  class CommandsGenerator

    def self.start
      self.new.run
    end

    def run
      program :name, 'iapserver'
      program :version, IAPServer::VERSION
      program :description, '查询苹果iap交易信息和票据认证信息'

      global_option('--sandbox', '是否为Sandbox环境，默认为Product环境。') { $sandbox = false }
      # default_command :receipt

      command :receipt do |c|
        c.syntax = 'iapserver receipt args [options]'
        c.description = 'iap票据验证'
        c.option '-p', '--password STRING', String, '共享密钥'
        c.option '-f', '--file FILE', String, 'Base64后的票据存放路径，格式：文本。'
        c.action do |args, options|
          IAPServer::Receipt.new.run(options, args)
        end
      end

      command :order do |c|
        c.syntax = 'iapserver order [order_id]'
        c.description = 'iap订单查询'
        c.action do |args, options|
          IAPServer::Order.new.run(options, args)
        end
      end

      command :history do |c|
        c.syntax = 'iapserver history [transaction_id]'
        c.description = 'iap历史交易查询'
        c.action do |args, options|
          IAPServer::History.new.run(options, args)
        end
      end

      command :transaction do |c|
        c.syntax = 'iapserver transaction [transaction_id]'
        c.description = 'iap交易详情'
        c.action do |args, options|
          IAPServer::Transaction.new.run(options, args)
        end
      end

      command :subscription do |c|
        c.syntax = 'iapserver subscription [transaction_id]'
        c.description = 'iap订阅信息'
        c.action do |args, options|
          IAPServer::Subscription.new.run(options, args)
        end
      end

      command :refund do |c|
        c.syntax = 'iapserver refund [transaction_id]'
        c.description = 'iap退款信息'
        c.action do |args, options|
          IAPServer::Refund.new.run(options, args)
        end
      end

      command :noti_history do |c|
        c.syntax = 'iapserver noti_history [transaction_id]'
        c.description = 'iap服务端通知'
        c.option '--lastdays INTEGER', Integer, '查询过去多少天的服务端通知[1-180]。默认30天'
        c.option '--only-failures', '仅请求未成功到达服务器的通知'
        c.option '--noti-type STRING', String, '通知类型。参考：`https://developer.apple.com/documentation/appstoreservernotifications/notificationtype`'
        c.option '--noti-subtype STRING', String, '参考：`https://developer.apple.com/documentation/appstoreservernotifications/subtype`'
        c.option '--token STRING', String, 'paginationToken'
        c.action do |args, options|
          options.default :lastdays => 30, :only_failures => false
          IAPServer::NotificationHistory.new.run(options, args)
        end
      end

      command :config do |c|
        c.syntax = 'iapserver config [options]'
        c.description = 'Apple Store Connect配置'
        c.option '-d', '--detail', '列出Apple Store Connect秘钥配置详情'
        c.option '-r', '--remove', '列出并选择删除配置的密钥'
        c.option '-a', '--add NAME', String, '添加单个配置'
        c.option '-c', '--config JSON PATH', String, 'Apple Store Connect配置。JSON: [{"name":"名称","key":"秘钥","kid":"秘钥ID","iss":"issuser id","bid":"bundle id"}]'
        #, &multiple_values_option_proc(c, "config", &proc { |value| value.split('=', 2) })
        c.action do |args, options|
          IAPServer::Config.new.run(options, args)
        end
      end
    end

    def multiple_values_option_proc(command, name)
      proc do |value|
        value = yield(value) if block_given?
        option = command.proxy_options.find { |opt| opt[0] == name } || []
        values = option[1] || []
        values << value
    
        command.proxy_options.delete option
        command.proxy_options << [name, values]
      end
    end
  end
end