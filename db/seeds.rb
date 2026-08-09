# 「小説を読む → 映画化を観る → 舞台の街に行く → そこで食べたものを再現する」
# という連鎖を caused_by で一本の線として繋いだ例。bin/rails db:seed で入る。

read = Recorder.start(
  subject: { kind: "book", title: "細雪", creator: "谷崎潤一郎", external_ids: { "isbn" => "9784101005058" } },
  event: { type: "did", occurred_on: Date.new(2026, 1, 14), rating: 5, note: "蒔岡家の四姉妹" }
)

watch = Recorder.start(
  subject: { kind: "film", title: "細雪 (1983)", creator: "市川崑" },
  event: { type: "did", occurred_on: Date.new(2026, 2, 3), rating: 4, caused_by: read.id, note: "原作を読んだ勢いで" }
)

visit = Recorder.start(
  subject: { kind: "place", title: "蘆屋川", creator: nil, lat: 34.7275, lng: 135.3050 },
  event: { type: "did", occurred_on: Date.new(2026, 3, 21), rating: 5, caused_by: watch.id, note: "花見の場面の川" }
)

Recorder.start(
  subject: { kind: "dish", title: "鯛の子の煮付け", creator: "細雪の食卓" },
  event: { type: "wished", occurred_on: Date.new(2026, 3, 22), caused_by: visit.id, note: "帰りに魚屋で鯛の子を見た" }
)

# 溜まっていく wished の例
[ [ "book", "痴人の愛", "谷崎潤一郎" ], [ "film", "鍵", "市川崑" ], [ "place", "旧グッゲンハイム邸", nil ],
  [ "dish", "ぼたん鍋", nil ], [ "book", "陰翳礼讃", "谷崎潤一郎" ], [ "place", "倚松庵", nil ] ].each_with_index do |(kind, title, creator), i|
  Recorder.start(
    subject: { kind:, title:, creator: },
    event: { type: "wished", occurred_on: Date.new(2026, 4, 1) + i }
  )
end

puts "seeded: #{Subject.count} subjects / #{Event.count} events"
