require 'sqlite3'
require 'active_record'
require 'net/http'
require 'uri'
require 'json'

#ああああ


ActiveRecord::Base.establish_connection(
        "adapter" => "sqlite3",
        "database" => "/root/mount/db.sqlite3"
        )
 
class AppNotification < ActiveRecord::Base
end 

# 通知用メソッド
# 引数　タイトル、本文、FCMトークン
def request_notification(title, body, fcmtoken)
  uri = URI.parse("https://android.googleapis.com/gcm/send")
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "key=AAAANqMQ0eI:APA91bEDFBvkmaYG8yZIoj_fY39pFDveGv10PFbKUtWRsq9Rvs4QqJEtSVF3I-_0xdHe2NoXMLnoJwQD9_RwfNusc4Vez-HZTmevlb7DvX5bXj2a-kVhzlTc-zIp4l10SU0V4YE1pcG0"
  request.body = JSON.dump({
    "registration_ids" => ["#{fcmtoken}"],
    "notification" => {
      "sound" => "dafault",
      "title" => title,
      "body" => body,
    }
  })

  #puts "Request: #{request.body}"
  
  req_options = {
    use_ssl: uri.scheme == "https",
  }
  
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end
end   

class AppUserEvent < ActiveRecord::Base
  events = AppUserEvent.where(event_start: Time.now..15.minutes.since).all
  events.each do |event|
    puts "Title:#{event.event_title}, User ID:#{event.user_id_id}"
  begin
    notification = AppNotification.find_by_user_id(event.user_id_id)
    puts "Flag: #{event.notification}, FCM Token: #{notification.fcmtoken}"
    if event.notification == 0
      # 通知メソッドの呼び出し
      body = "#{event.event_start.in_time_zone('Tokyo')} より活動開始の時間です。"
      request_notification(event.event_title,body,notification.fcmtoken)
      event.notification = 1
      event.save
    end
  rescue
    puts "FCM not found"
  end
    
 end
end
