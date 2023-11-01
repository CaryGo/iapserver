require "uuidtools"
require 'jwt'
require 'openssl'
require 'json'
require_relative 'appstore_config'

module IAPServer
	class JWTTools
		def self.generate
			config = IAPServer::AppStoreConfig.default_config
			raise "获取秘钥信息失败，请检查。" if config.nil?
			
			key, kid, iss, bid = config['key'], config['kid'], config['iss'], config['bid']
			# fix key
			key = key.split("\\n").join("\n") if key.include?("\\n")
			generate_token(key, kid, iss, bid)
		end

		# 秘钥串、秘钥ID、Issuer ID、bundle id
		def self.generate_token(key, kid, iss, bid)
			# JWT Header
			header = {
				"alg": "ES256", # 固定值
				"kid": kid, # private key ID from App Store Connect
				"typ": "JWT" # 固定值
			}

			iat = Time.new
			# JWT Payload
			payload = {
				"iss": iss, # Your issuer ID from the Keys page in App Store Connect
				"aud": "appstoreconnect-v1", # 固定值
				"iat": iat.to_i, # 令牌生成时间，UNIX时间单位，秒
				"exp": iat.to_i + 60 * 60, # 令牌失效时间，60 minutes timestamp
				"nonce": UUIDTools::UUID.timestamp_create.to_s, # An arbitrary number you create and use only once
				"bid": bid # Your app's bundle ID
			}

			ecdsa_key = OpenSSL::PKey::EC.new key
			# JWT token
			token = JWT.encode payload, ecdsa_key, algorithm='ES256', header_fields=header
			token
		end

		def self.good_signature(jws_token)
		    realpath = File.expand_path("#{File.dirname(__FILE__)}/../../assets/AppleRootCA-G3.cer")
		    raw = File.read "#{realpath}"
		    apple_root_cert = OpenSSL::X509::Certificate.new(raw)

		    parts = jws_token.split(".")
		    decoded_parts = parts.map { |part| Base64.decode64(part) }
		    header = JSON.parse(decoded_parts[0])
		    # puts "Header：#{decoded_parts[0]}"
		    # puts "Payload：#{decoded_parts[1]}"

		    cert_chain =  header["x5c"].map { |part| OpenSSL::X509::Certificate.new(Base64.decode64(part))}
		    return false unless cert_chain.last == apple_root_cert

		    for n in 0..(cert_chain.count - 2)
		      return false unless cert_chain[n].verify(cert_chain[n+1].public_key)
		    end

		    begin
		      decoded_token = JWT.decode(jws_token, cert_chain[0].public_key, true, { algorithms: ['ES256'] })
		      !decoded_token.nil?
		    rescue JWT::JWKError
		      false
		    rescue JWT::DecodeError
		      false
		    end
		end

		def self.payload(jws_token)
		    parts = jws_token.split(".")
		    decoded_parts = parts.map { |part| Base64.decode64(part) }
		    decoded_parts[1]
		end

		def self.header(jws_token)
		    parts = jws_token.split(".")
		    decoded_parts = parts.map { |part| Base64.decode64(part) }
		    decoded_parts[0]
		end
	end
end