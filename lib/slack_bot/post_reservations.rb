# incoming-webhookのURLを記述する
ROOM_URL = ENV['ROOM_URL']
CALENDAR_URL = ENV['CALENDAR_URL']

require 'net/http'
require 'uri'
require 'json'
require 'time'

module SlackBot
  module PostReservations
    def post_reservations
      reservations = parse_json
      return if reservations.empty?

      today = Time.now.strftime('%Y/%m/%d')
      url = CALENDAR_URL + "?view=agendaDay&date=today"
      post(<<-EOS)
本日(#{today})の会議室予約状況です。

#{reservations.join("\n")}

#{url}
      EOS
    end

    private
    def get_json
      uri = URI.join(URI.parse(CALENDAR_URL), '/calendar/reservations')
      Net::HTTP.get(uri)
    end

    def parse_json
      parsed_json = JSON.parse(get_json)

      parsed_json.map do |reservation|
        start_time = Time.parse(reservation['start']).strftime('%H:%M')
        end_time = Time.parse(reservation['end']).strftime('%H:%M')
        reservation_time = "#{start_time}-#{end_time}"
        title_and_room = "#{reservation['title']}  #{reservation['room']}"
        "#{reservation_time}  #{title_and_room}"
      end
    end

    def post(text)
      Net::HTTP.post_form(URI.parse(ROOM_URL),
                          { "payload" => { "text" => text }.to_json })
    end
  end
end
