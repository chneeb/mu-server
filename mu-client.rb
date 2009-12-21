#!/usr/bin/ruby

require 'drb'
#require 'sqlite3'

DRb.start_service
mu_server = DRbObject.new(nil, 'druby://10.201.55.35:8001')
mu_server.index("neeb03")
mail = mu_server.find("neeb03", ARGV.join).first
puts mu_server.retrieve_mail("neeb03", mail["mpath"])
