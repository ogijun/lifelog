# YouTube の動画ページ。動画そのものも体験の対象なので「動画」として記録する
# (紹介された本を「読みたい」へのきっかけにできる)。チャンネル名はタイトルに無いので取れない。
module Capture
  module Youtube
    WATCH = %r{\Ahttps://(?:www\.|m\.)?youtube\.com/watch\?(?:[^#]*&)?v=([\w-]{11})}
    SHORT = %r{\Ahttps://(?:youtu\.be/|(?:www\.|m\.)?youtube\.com/shorts/)([\w-]{11})}
    # 未読の通知があるとタイトルの頭に「(3) 」が付く。
    NOTIFICATIONS = /\A\(\d+\) /

    module_function

    def call(url:, title:)
      video = WATCH.match(url) || SHORT.match(url) or return
      name = title.delete_suffix(" - YouTube").sub(NOTIFICATIONS, "")
      Hit.new(kind: "video", subject: { title: name, url: "https://www.youtube.com/watch?v=#{video[1]}" })
    end
  end
end
