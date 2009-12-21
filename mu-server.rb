#!/usr/bin/ruby

require 'etc'
require 'drb'
require 'sqlite3'

PORT = '8001'
DATABASE_FILENAME = '.mu/mu-sqlite.db-0.4'

class MuServer
  def su(user, &block)
    new_uid = Etc.getpwnam(user).uid
    old_uid = Process.euid
    unless old_uid == new_uid
      Process::UID.change_privilege(new_uid)
    end
    info = Etc.getpwnam(user)
    Dir.chdir(info.dir) do
      block.call(info)
    end
    unless old_uid == new_uid
      Process::UID.change_privilege(old_uid)
   end
  end
  private :su

  def find(user, expression)
    result = []
    su(user) do |info|
      msg_ids = %x{mu-find --format=m #{expression}}.split($/)
      db = SQLite3::Database.new(File.join(info.dir, DATABASE_FILENAME))
      db.results_as_hash = true
      rows = db.execute("SELECT * FROM MESSAGE WHERE MSG_ID IN (#{msg_ids.collect{|x| "'#{x}'"}.join(",")})")
      result = rows.collect do |row|
        message = {}
        row.keys.each {|field| message[field] = row[field] unless field.kind_of? Fixnum}
        message
      end
    end
    result
  end

  def retrieve_mail(user, filename)
    result = nil
    su(user) do |info|
      result = File.new(filename).read if filename =~ /^#{info.dir}/
    end
    result
  end

end

mu_server = MuServer.new
DRb.start_service("druby://0.0.0.0:#{PORT}", mu_server)
trap('INT') { DRb.thread.kill; exit }
DRb.thread.join

