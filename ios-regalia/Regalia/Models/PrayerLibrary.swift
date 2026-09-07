import Foundation

/// A long-form written prayer, tagged for matching to the person praying it.
nonisolated struct TaggedPrayer: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let paragraphs: [String]
    /// Tag values: mood rawValues ("anxious"…), reason rawValues ("mornings"…), or "general".
    let tags: [String]
}

/// Every long-form prayer in Regalia, with the matcher that picks one per morning.
/// Prayers are matched to today's mood and the user's main reason, and never repeat
/// until the whole pool has been prayed through.
nonisolated enum PrayerLibrary {

    /// The name slot. It is always written as a self-appositive — `", {name},"` — so the
    /// sentence reads correctly both with a name ("Here I am, Sarah, bringing You…") and
    /// without one ("Here I am, bringing You…"). Never place it where the following verb
    /// would have to agree with a third person.
    static let nameToken = "{name}"

    /// Closings, longest first, so stripping an existing one never leaves a fragment behind.
    private static let closings = ["In Jesus' name, Amen.", "in Jesus' name, Amen.", "Amen."]

    /// Selects, personalises, and returns today's prayer as a persisted `DailyPrayer`.
    /// Fallback order: mood + reason together → mood → reason → general.
    nonisolated static func nextPrayer(
        mood: Mood?,
        reason: SeekingReason?,
        name: String,
        used: inout [String]
    ) -> DailyPrayer? {
        var pools: [[TaggedPrayer]] = []
        if let mood, let reason {
            pools.append(matching(mood, reason))
        }
        if let mood { pools.append(matching(mood)) }
        if let reason { pools.append(matching(reason)) }
        pools.append(general)

        for pool in pools {
            let remaining = pool.filter { !used.contains($0.id) }
            if let pick = remaining.randomElement() {
                used.append(pick.id)
                return compose(pick, name: name)
            }
        }

        // The whole library has been prayed through — start a fresh cycle
        // from the most specific pool that has content.
        used = []
        guard let pool = pools.first(where: { !$0.isEmpty }),
              let pick = pool.randomElement() else { return nil }
        used.append(pick.id)
        return compose(pick, name: name)
    }

    private nonisolated static func matching(_ mood: Mood, _ reason: SeekingReason) -> [TaggedPrayer] {
        all.filter { $0.tags.contains(mood.rawValue) && $0.tags.contains(reason.rawValue) }
    }

    private nonisolated static func matching(_ mood: Mood) -> [TaggedPrayer] {
        all.filter { $0.tags.contains(mood.rawValue) }
    }

    private nonisolated static func matching(_ reason: SeekingReason) -> [TaggedPrayer] {
        all.filter { $0.tags.contains(reason.rawValue) }
    }

    /// Personalises the prayer with the user's name and applies the enforced closing,
    /// so no prayer can ever ship without one.
    nonisolated static func compose(_ prayer: TaggedPrayer, name: String) -> DailyPrayer {
        var paragraphs = prayer.paragraphs.map { personalise($0, name: name) }

        if let last = paragraphs.last {
            paragraphs[paragraphs.count - 1] = sealed(last)
        }

        return DailyPrayer(id: prayer.id, title: prayer.title, body: paragraphs.joined(separator: "\n\n"))
    }

    /// Fills the name slot, or closes it up cleanly when no name was given.
    private nonisolated static func personalise(_ paragraph: String, name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else {
            return paragraph.replacingOccurrences(of: nameToken, with: trimmed)
        }
        // Collapse the appositive to a single comma, then clear any stray token forms.
        return paragraph
            .replacingOccurrences(of: ", \(nameToken),", with: ",")
            .replacingOccurrences(of: "\(nameToken), ", with: "")
            .replacingOccurrences(of: nameToken, with: "")
    }

    /// Applies "in Jesus' name, Amen." with the casing the preceding text calls for:
    /// a new sentence after a full stop, a continuation after a comma.
    private nonisolated static func sealed(_ paragraph: String) -> String {
        var text = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        for closing in closings where text.hasSuffix(closing) {
            text = String(text.dropLast(closing.count)).trimmingCharacters(in: .whitespaces)
            break
        }

        guard let last = text.last else { return "In Jesus' name, Amen." }
        if last == "," {
            return "\(text) in Jesus' name, Amen."
        }
        if last == "." || last == "!" || last == "?" {
            return "\(text) In Jesus' name, Amen."
        }
        return "\(text), in Jesus' name, Amen."
    }

    // MARK: - For each mood

    private nonisolated static let byMood: [TaggedPrayer] = [
        TaggedPrayer(
            id: "lp-anxious-1",
            title: "When the morning feels heavy",
            paragraphs: [
                "Father, You are not startled by what this day holds. You watched every hour of it before I opened my eyes, and You are already standing in the last one, waiting for me. You have never once been late to help me.",
                "Here I am, {name}, bringing You the weight I woke up carrying. I confess I have been rehearsing the day instead of praying it — borrowing tomorrow's trouble before breakfast. Take it out of my hands. I cannot carry it and Your peace at the same time, and I choose Your peace.",
                "So go ahead of me now: into the room, the message, the decision I keep circling. Quiet the what-ifs before they finish their sentences. Teach me to pray when it rises instead of reaching for something to numb it."
            ],
            tags: ["anxious", "anxiety"]
        ),
        TaggedPrayer(
            id: "lp-anxious-2",
            title: "For a mind that won't stop",
            paragraphs: [
                "Lord, You are the same God at 6 a.m. as You are at midnight. Nothing about You changes with the light. You are still sovereign over every thought that won't sit still.",
                "I confess that I try to think my way to peace instead of praying my way there. My mind runs like a feed that never ends, and I have been scrolling it hoping something settles it. Forgive me. Take every thought captive and hand it back to me quiet.",
                "Today, let me return to You the way I used to return to my phone — quickly, often, without thinking. You have more patience than that feed has content. Be my rest."
            ],
            tags: ["anxious", "identity"]
        ),
        TaggedPrayer(
            id: "lp-tempted-1",
            title: "Before the pull comes",
            paragraphs: [
                "Lord of Hosts, You fought this battle first and won it. The grave is empty and the enemy is a defeated thing rattling a chained door. I do not stand today to earn a victory — I stand inside one.",
                "I confess how often I have wandered toward the flame and called it curiosity. You know the hour the pull comes, and so do I. When it does, give me the courage to run — not away from You, but to You.",
                "Guard my eyes and my thumbs before my will is even awake. Make the way out so plain I would have to step over it to fall. I want to end this day clean, and You want that more than I do."
            ],
            tags: ["tempted", "purity"]
        ),
        TaggedPrayer(
            id: "lp-tempted-2",
            title: "For the fight I didn't choose",
            paragraphs: [
                "Father, You know the war I fight in the minutes when no one is watching. You are a God who was tempted in every way and never sinned — so You do not look at my struggle with disgust. You look at it with mercy.",
                "I confess that I have believed the lie that I am the exception, that I will fall because I always fall. But no temptation has overtaken me except what is common to everyone, and You are faithful. Break that story today. Write a new one, one refused moment at a time.",
                "Arm me now: truth buckled at my waist, faith raised before the arrows fly. When the pull comes, let my first instinct be prayer, not the app. I stand because You stood for me,"
            ],
            tags: ["tempted", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-numb-1",
            title: "When I feel nothing",
            paragraphs: [
                "God, You are the God who made feeling and the God who outlasts its absence. You loved me on the days my heart was shouting and on the days it was silent. Both are true today.",
                "I confess I have been medicating the numbness with noise instead of bringing the silence to You. I feel nothing, and the nothing scares me. So I bring You the nothing. You raised a dead world to life — You can warm a cold heart.",
                "Keep me awake today even if nothing stirs. Do not let me confuse comfort with peace, or scrolling with living. If joy is a seed, let me keep watering it in the dark, trusting You for the spring."
            ],
            tags: ["numb"]
        ),
        TaggedPrayer(
            id: "lp-numb-2",
            title: "For the spark to return",
            paragraphs: [
                "Lord, You are the God of the first love. You are the One my heart burned for once, and You have never moved from where I left You standing.",
                "I confess what drained me: a hundred small refusals, a thousand little scrolls, a heart spent in ten-second pieces. Restore to me the joy of Your salvation — not the feeling I remember, but the thing underneath the feeling.",
                "Light it back up in Your time and Your way. Give me one true moment today — one verse that lands, one mercy noticed, one prayer that feels like it reached the ceiling. I will take that as the ember."
            ],
            tags: ["numb", "identity"]
        ),
        TaggedPrayer(
            id: "lp-grateful-1",
            title: "For a warm morning",
            paragraphs: [
                "Father, every good and perfect gift comes down from You — including the calm I woke up to this morning. You are the Giver, and today You gave gently.",
                "I confess how quickly I forget days like this. I take the warm morning and spend it hunting for the next thing. Not today. I name the gifts out loud: breath, rest, the people who love me, Your Word still speaking.",
                "Let this gratitude outlast the morning. When the day turns, let thankfulness be the reflex instead of the scroll. Guard the ground You gave me today."
            ],
            tags: ["grateful", "presence"]
        ),
        TaggedPrayer(
            id: "lp-grateful-2",
            title: "Thank You first",
            paragraphs: [
                "Lord, before anything else — thank You. You did not owe me this morning, and You gave it anyway. Mercy was waiting before my alarm was.",
                "I confess that my first attention usually goes to a glass rectangle instead of a gracious Father. Forgive me. I want to give You the first word of the day, not the last scroll of it.",
                "Fill the space where the feed used to live with something better: Your presence, Your voice, the faces I love. Let me walk today as someone given everything I could never earn."
            ],
            tags: ["grateful", "mornings"]
        ),
        TaggedPrayer(
            id: "lp-weary-1",
            title: "When I'm running on empty",
            paragraphs: [
                "Jesus, You said, “Come to Me, all who are weary, and I will give you rest.” I am here. I am the exact person that sentence was written for, and I am taking You at Your word.",
                "I confess I have been running on willpower and calling it faith. I am tired of trying harder. So I stop. Take what I cannot carry — the guilt, the loop, the fear that this will never change — and carry it.",
                "Let me walk today at Your pace, not mine. One thing at a time. One faithful hour. If I fall, You are not surprised, and You are not done. Be my strength where mine ran out."
            ],
            tags: ["weary", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-weary-2",
            title: "Carried today",
            paragraphs: [
                "Father, You are the shepherd who carries the lamb — not the coach who shouts from the sideline. You do not ask the wounded to run. You pick them up.",
                "I confess I have been pretending to be stronger than I am, and it has made me slower, not faster. Here is the truth: I am weak today, and Your power is made perfect in weakness. I am handing You the whole day before it hands me anything.",
                "Carry me through the hours ahead. Put people in my path who help, and shield me from what drains. Let me rest in You even while I move."
            ],
            tags: ["weary"]
        ),
        TaggedPrayer(
            id: "lp-anxious-3",
            title: "When the what-ifs start early",
            paragraphs: [
                "Father, You already know what today holds, and You are not pacing the halls over it. You sit enthroned above every possibility, and none of them frightens You.",
                "Here I am, {name}, handing You a mind that wakes up sprinting. I confess I have run every bad outcome to its end before my feet touched the floor, and You were in none of those endings.",
                "Slow me down to Your pace. One hour at a time is enough — You promised that. Let the first hour be Yours, and let the rest follow in peace."
            ],
            tags: ["anxious", "mornings"]
        ),
        TaggedPrayer(
            id: "lp-anxious-4",
            title: "For the phone in my hand first thing",
            paragraphs: [
                "Lord, You were speaking before I ever scrolled, and Your voice has not grown quieter. The noise grew louder — that's all. This morning I want the quiet voice.",
                "I confess I have reached for headlines and notifications like they were bread. They left me hungrier than they found me. Forgive me, and feed me this morning from Your word instead.",
                "Set my attention like a compass toward You. When the feed calls, let Your call be the one I answer first, and the one I answer most."
            ],
            tags: ["anxious"]
        ),
        TaggedPrayer(
            id: "lp-anxious-5",
            title: "For a heart that can't sit still",
            paragraphs: [
                "Father, You are not impressed by my busyness, and You are not offended by my stillness. You simply ask me to be still and know that You are God — and I have barely tried.",
                "I confess that stillness feels unsafe to me, like something is being missed. But what I keep missing is You. Teach me that sitting with You is not doing nothing; it is the most productive thing I will do today.",
                "Guard my rest today. When my body stops and my mind keeps running, gather my thoughts and bring them home. Be my stillness, and let my day be built on it."
            ],
            tags: ["anxious", "presence"]
        ),
        TaggedPrayer(
            id: "lp-tempted-3",
            title: "For the weak hour",
            paragraphs: [
                "Lord, You know my weak hour better than I do — the time of day the old appetite comes calling, wearing something new. You were there the last time I fell, and You are here before the next one.",
                "I confess I have negotiated with temptation as though it negotiated back. It doesn't. It takes. So today I make no deals: when the hour comes, I run to You, {name}, and I let You do the fighting.",
                "Meet me in that hour with power, not with a lecture. Make the way out so obvious I would have to be stubborn to miss it. And if I stumble, catch me before the second step."
            ],
            tags: ["tempted", "purity"]
        ),
        TaggedPrayer(
            id: "lp-tempted-4",
            title: "For the eyes",
            paragraphs: [
                "Father, You made my eyes to see glory, and I have aimed them at shadows. You are patient with me beyond what I understand, and kinder than I deserve.",
                "I confess what I have let in through those small doors. Nothing ever walked out the way it walked in. Today I set a guard at the gate: the first glance is mine to give, the second is Yours to stop.",
                "Fill my eyes with better things — the people in front of me, the sky You painted, the work You gave me. Make beauty itself an argument back to You, and let my gaze stay clean."
            ],
            tags: ["tempted"]
        ),
        TaggedPrayer(
            id: "lp-tempted-5",
            title: "Standing before the screen",
            paragraphs: [
                "Lord, the screen is small and the war is not. You know the exact shape of this fight in my pocket, and You have already won it at the cross.",
                "I confess, {name}, that I have treated this device as neutral, and it never was. It disciples me by default, and I have let it. Today I take the authority back.",
                "Put the sword in my hand before the screen lights up: Your word, ready, sharp. Let one verse be enough to end the argument. Tonight, let me set the phone down and stand up clean."
            ],
            tags: ["tempted", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-numb-3",
            title: "When joy is a rumour",
            paragraphs: [
                "God, You are the source of every joy I have ever felt, including the ones I forgot. You do not ration joy to those who feel it loudly.",
                "I confess, {name}, that I have stopped expecting anything from today. That is not humility; that is unbelief with a quiet voice. Wake up my expectations.",
                "Send one mercy today and give me eyes to catch it. Then another. Teach me to collect them like coins until the pocket rattles. You are not done warming this heart."
            ],
            tags: ["numb"]
        ),
        TaggedPrayer(
            id: "lp-numb-4",
            title: "For the going-through-the-motions",
            paragraphs: [
                "Lord, You see that I still show up — to prayer, to work, to people — but the lights are off inside. You are not fooled, and You are not angry. You are near.",
                "I confess that routine has become my shelter from feeling. But You did not save me to manage my faith; You saved me to live it. Breathe on the routine until it breathes back.",
                "Today, let one familiar thing become new: one verse, one prayer, one conversation. Turn the lights on in that one place, and I will call it the beginning."
            ],
            tags: ["numb", "identity"]
        ),
        TaggedPrayer(
            id: "lp-numb-5",
            title: "Asking for the hunger back",
            paragraphs: [
                "Father, hunger is a gift, and I have lost mine. You fed a people in a wilderness for forty years and never missed a morning. You can feed me in this flat one.",
                "I confess I have fed my soul on crumbs and wondered why I was starving. Put the hunger back in me, {name}, the kind that pants for streams of water.",
                "Make Your word taste like bread again. Make prayer feel like a table instead of a task. And when the hunger returns, teach me to keep it fed at Your table, not the world's."
            ],
            tags: ["numb", "purity"]
        ),
        TaggedPrayer(
            id: "lp-grateful-3",
            title: "For small mercies",
            paragraphs: [
                "Father, the big mercies get the songs, but the day was carried by small ones: breath, morning light, a message from a friend, a door held open. You hid a thousand gifts inside an ordinary day.",
                "I confess, {name}, that I walk past most of them with my eyes on what's missing. Open my hands this morning. Gratitude is a muscle, and it has been idle.",
                "Slow me down enough to catch three of them today, and let each one preach: the Giver is good, and He is here. Gratitude will do more for my guard than vigilance ever could."
            ],
            tags: ["grateful"]
        ),
        TaggedPrayer(
            id: "lp-grateful-4",
            title: "When it's been a hard season",
            paragraphs: [
                "Lord, thanking You right now is not natural. The season has been long and loud with loss. But You never asked me to feel grateful first — only to give thanks, and let the feeling follow.",
                "I say it by faith this morning, {name}, with nothing but Your promises to stand on: You are still good. I confess I have let the hard season edit Your character, and I take it back.",
                "Be my evidence today. Let one clear kindness from You land where I can see it, and let my thanksgiving grow from there, like light in a slow dawn."
            ],
            tags: ["grateful", "presence"]
        ),
        TaggedPrayer(
            id: "lp-grateful-5",
            title: "For the people who stayed",
            paragraphs: [
                "Father, You love through people, and You have not stinted: the ones who checked in, the ones who prayed when I couldn't, the ones who stayed. Every one of them was Your handwriting.",
                "I confess I have received their love like it was owed. Today I name it, {name}: grace, delivered by hand. Thank You for every face that carried it.",
                "Make me that kind of person for someone else today. Let me be somebody's answered prayer before lunch. And guard the gratitude — don't let it end as a feeling."
            ],
            tags: ["grateful", "mornings"]
        ),
        TaggedPrayer(
            id: "lp-weary-3",
            title: "When rest feels like failure",
            paragraphs: [
                "Father, You rested — not because You had to, but because rest is holy. I have been treating sleep like a debt and stillness like sin, and I am running on fumes.",
                "I confess, {name}, that I have worn exhaustion like a medal and called it faithfulness. It isn't. It's pride with a schedule.",
                "Teach me to stop like You mean it. Let tonight's sleep be worship, and tomorrow's strength a gift, not a wage. I am a creature, and You made me one on purpose."
            ],
            tags: ["weary"]
        ),
        TaggedPrayer(
            id: "lp-weary-4",
            title: "For the long obedience",
            paragraphs: [
                "Lord, this road is long, and I have been measuring the whole distance instead of the next step. You never asked me to carry the year — only this day.",
                "I confess the gap between where I am and where I want to be has discouraged me more than sin itself has. Meet me in that gap, {name}, and walk it with me one morning at a time.",
                "Give me today's bread and today's strength, and let tomorrow fend for itself until it arrives. Faithfulness is a slow miracle — do it in me, slowly."
            ],
            tags: ["weary", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-weary-5",
            title: "Held at the end of the rope",
            paragraphs: [
                "Father, the rope is short today. But You specialize in ends — of ropes, of strength, of me. Everything You have ever rebuilt, You rebuilt from the point where it ran out.",
                "I confess, {name}, that I have hidden how tired I am, even from You, as if You hadn't already seen. Here it is — all of it. I would rather be carried than impressive.",
                "Carry what I put down. Raise what fell. And when I wake tomorrow, let me find that Your mercy got here first, the way it always does."
            ],
            tags: ["weary", "identity"]
        )
    ]

    // MARK: - For each reason

    private nonisolated static let byReason: [TaggedPrayer] = [
        TaggedPrayer(
            id: "lp-mornings-1",
            title: "For the first hour",
            paragraphs: [
                "Father, You are the God of new mornings — mercy made new before my feet touch the floor. The day is Yours before it is mine.",
                "I come to You now, {name}, confessing that the first hour has been the hardest to give up. It belongs to the feed, the news, the noise. Today I give it back to You before anyone else can have it. Guard the first hour, and You will have guarded the whole day.",
                "Let this hour be the keystone: Your Word first, Your voice first, Your peace first. When my hand reaches for the phone out of habit, meet it with something better."
            ],
            tags: ["mornings", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-mornings-2",
            title: "Before the feed wakes",
            paragraphs: [
                "Lord, You never sleep. You were awake through the whole night while I slept, and this quiet hour was Your idea before it was mine.",
                "I confess that I have been letting strangers' thoughts be the first thoughts of my day. Forgive me. Before the feed wakes, before the world's opinions find me, I want to hear Yours.",
                "Speak into this quiet. Set the agenda for today — not the algorithm's agenda, Yours. I am choosing the better portion, and I am asking You to help me keep choosing it."
            ],
            tags: ["mornings", "anxiety"]
        ),
        TaggedPrayer(
            id: "lp-purity-1",
            title: "For a clean heart",
            paragraphs: [
                "God, You are the One who creates clean hearts — You do not sell them, and You do not demand them polished first. You make them new out of nothing, the way You made everything.",
                "Create in me a clean heart, O God. I confess the patterns I have nursed instead of killed, the images I have let in, the thresholds I moved one inch at a time. I am done moving the line. Draw it back where You put it.",
                "Guard my eyes today — the second scroll, the harmless-looking tap, the slow drift. Make holiness attractive to me again. I would rather fight beside You than fall alone."
            ],
            tags: ["purity"]
        ),
        TaggedPrayer(
            id: "lp-purity-2",
            title: "Breaking the old habit",
            paragraphs: [
                "Lord, You are the God of exodus — You brought a people out of a house they could not leave on their own. You are still doing that. I am asking You to do it for me.",
                "I confess how deep this habit goes, how it knows my weak hours and my tired excuses. But it does not know anything about Your mercy. Break the loop at its root, not just its surface. Where I have agreed with the enemy, let me disagree out loud today.",
                "When the old door creaks open, stand in it. Give me the strength to walk a different road, one day at a time, until the old one grows over. I am not my habit. I am Yours."
            ],
            tags: ["purity", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-identity-1",
            title: "Whose I am",
            paragraphs: [
                "Father, You are the One who calls things that are not as though they are. You spoke light into darkness, and You speak identity over me — before I perform, before I earn, before I am ready.",
                "I confess I have been asking the world who I am and believing the answer. Metrics, streaks, likes, the face in the mirror on a bad day. Cut through all of it. Remind me this morning whose I am, and I will live the rest of the day from that name.",
                "Let me carry my name like armour instead of like a wound. When the accuser reads my history to me, let me read him my adoption. I am a child of the King, and today I will act like it."
            ],
            tags: ["identity"]
        ),
        TaggedPrayer(
            id: "lp-identity-2",
            title: "Not what the feed says",
            paragraphs: [
                "Lord, You are the audience of one. You see in secret, You know my unseen hours, and You keep records the feed cannot edit.",
                "I confess I have been measuring myself against highlight reels built by people as tired as I am. Everyone is ahead of me — that is the lie, and I have been paying rent on it. Evict it today. I am not behind; I am on a road You built for me.",
                "Quiet the comparison before it starts the tally. Give me eyes for my own field and joy for my own harvest. I was Your idea before the world had opinions about me."
            ],
            tags: ["identity", "presence"]
        ),
        TaggedPrayer(
            id: "lp-anxiety-1",
            title: "Quiet at the root",
            paragraphs: [
                "Father, You are the God of all comfort, who comforts us in all our troubles. You are not annoyed by my anxiety. You stand ready to carry it.",
                "I confess I have been treating peace like a prize I have to win by controlling everything. I cannot. So I bring You the anxious places — the ones with names and the ones I cannot even name yet. Trade my racing for Your rest.",
                "Let Your peace stand guard at the gates of my heart today. When worry knocks, let prayer answer first. And when I reach for something to drown the noise, let it be Your voice and not a screen."
            ],
            tags: ["anxiety", "anxious"]
        ),
        TaggedPrayer(
            id: "lp-anxiety-2",
            title: "The peace I scroll past",
            paragraphs: [
                "Lord, You are peace itself — not the absence of trouble, but a presence inside it. The world cannot give what You give, and it cannot take what You hold.",
                "I confess I have been hunting for peace in the feed, the way someone digs in sand for water. Forgive me. Show me how still I am allowed to be. Teach my body that silence is safe, that being unreachable for an hour does not end the world.",
                "Plant me by quiet water today. Let stillness feel like home instead of like danger. Be my calm in every room I walk into."
            ],
            tags: ["anxiety", "presence"]
        ),
        TaggedPrayer(
            id: "lp-presence-1",
            title: "For the people in front of me",
            paragraphs: [
                "Father, You are love, and love is always a face — never a feed. You came in person. You looked people in the eyes. That is how You loved the world, and it is how You are calling me to love.",
                "I confess I have been giving the people I love the leftovers of my attention. Half a conversation, half a meal, half a presence. Forgive me. Give back to them the hours I have been spending with strangers on a screen.",
                "Today, make me all the way here. Eyes up. Phone down. Let the people in front of me feel like they matter more than anything behind the glass — because they do."
            ],
            tags: ["presence"]
        ),
        TaggedPrayer(
            id: "lp-presence-2",
            title: "Eyes up today",
            paragraphs: [
                "Lord, You are the God who set every moment, and You have put real people in my real day. Nobody in the feed was placed in my hours by You, but the people in my house were.",
                "I confess the small vanishings — into my pocket, into my palm, into a world of other people's moments while mine walk past me. Forgive me. Open my eyes to the ones You have placed beside me.",
                "Let me notice today: the question behind a question, the moment someone needs me to look up. Make my presence a gift, not a transaction. I want to be where my body is."
            ],
            tags: ["presence", "mornings"]
        ),
        TaggedPrayer(
            id: "lp-discipline-1",
            title: "One faithful day",
            paragraphs: [
                "Father, You are the God of faithfulness, and You build Your kingdom one faithful day at a time. You are not in a hurry, and You have never been impressed by my speeches — only by my surrender.",
                "I confess I want the mountain moved today, and You are asking for one stone. So here is one day. One hour. One no said at the right moment. Make my discipline a form of worship instead of a cage I rattle.",
                "When today is won, do not let me rest on it. And when I fail, do not let me stay down. Teach my hands to war and my heart to rest. Steady me, day after day, until steadiness becomes who I am."
            ],
            tags: ["discipline"]
        ),
        TaggedPrayer(
            id: "lp-discipline-2",
            title: "Strength, not willpower",
            paragraphs: [
                "Lord, You are the vine and I am the branch, and I have been trying to grow fruit by clenching harder. You never asked me to be my own source.",
                "I confess my self-reliance dressed up as strength. I cannot white-knuckle this, and I have the record to prove it. Grow in me what willpower could never build — a want-to that agrees with You.",
                "Fill me with Your Spirit today: self-discipline that is really Your life in mine. Meet me at the small moments where the battle is actually won or lost. I would rather have Your strength than my resolve."
            ],
            tags: ["discipline", "weary"]
        ),
        TaggedPrayer(
            id: "lp-mornings-3",
            title: "The hour before the hour",
            paragraphs: [
                "Father, before the alarm, before the news, before anyone wants anything from me — that hour belongs to You, and I am done giving it away.",
                "I confess I have been paying the world its wages first and tithing You what's left. Reverse it today, {name}, and watch what the day becomes.",
                "Wake my soul before my phone. Let the first voice I hear be Yours, and let every later voice be measured against it."
            ],
            tags: ["mornings"]
        ),
        TaggedPrayer(
            id: "lp-mornings-4",
            title: "For slow starts",
            paragraphs: [
                "Lord, some mornings the engine turns over slowly, and shame arrives before the coffee does. You are not standing over me with a stopwatch. You are sitting at the table, waiting to eat with me.",
                "I confess, {name}, that I have called myself lazy when I was really just tired, and tired is not a sin. You made the night for rest, not for guilt.",
                "Meet me at whatever speed I have. A slow start with You beats a fast start without You. Take the morning as it comes, and make it enough."
            ],
            tags: ["mornings", "weary"]
        ),
        TaggedPrayer(
            id: "lp-purity-3",
            title: "The second look",
            paragraphs: [
                "God, purity is not one heroic refusal — it is a hundred small turnings, all day, mostly unseen. You see all of them, and You delight in every single one.",
                "I confess I have been waiting to feel like fighting before I fight. The feeling may never come, {name}, so I am asking for obedience instead.",
                "Win the second look today. And the third. Let holiness be built the way stone walls are: one plain stone at a time, until the wall holds."
            ],
            tags: ["purity"]
        ),
        TaggedPrayer(
            id: "lp-purity-4",
            title: "When the habit whispers at night",
            paragraphs: [
                "Father, the nights are quiet and the whispers are not. But You keep watch over me while I sleep and while I lie awake — You have never once dozed off on duty.",
                "I confess, {name}, that I have treated the night as the enemy's property and surrendered it without a fight. Take it back.",
                "Stand between me and the glow of the screen tonight. Let prayer be the last thing I touch. And if I wake restless, let Your word be the first voice I hear."
            ],
            tags: ["purity"]
        ),
        TaggedPrayer(
            id: "lp-identity-3",
            title: "Named before formed",
            paragraphs: [
                "Father, You named me before anyone formed an opinion of me. Before the metrics, the mirrors, the comments — You spoke, and the word was mine.",
                "I confess, {name}, that I have let strangers with keyboards outvote You. Close the polls.",
                "Let me wear Your name today like a crown that fits. When comparison knocks, let identity answer. I do not need to be impressive; I need to be Yours."
            ],
            tags: ["identity"]
        ),
        TaggedPrayer(
            id: "lp-identity-4",
            title: "Not the sum of my history",
            paragraphs: [
                "Lord, You keep my records differently. Where the accuser reads my history, You read my adoption. Where I count failures, You count a cross.",
                "I confess, {name}, that I have been carrying a file I was never meant to hold. Take it. It was nailed shut two thousand years ago.",
                "Let me live today out of Your verdict, not my archive. When the old evidence resurfaces, let grace overrule it — out loud, in my own voice."
            ],
            tags: ["identity"]
        ),
        TaggedPrayer(
            id: "lp-anxiety-3",
            title: "The body that won't settle",
            paragraphs: [
                "Father, You made this body, and You know what adrenaline does to it at midnight. You are not standing at a distance telling me to calm down. You are the calm, standing close.",
                "I confess, {name}, that I have scolded my own breathing instead of bringing it to You. Here — this racing heart is Yours too.",
                "Slow me down by Your Spirit, breath by breath. Let my body learn that I am safe in Your hands, and let my sleep tonight be deep and guarded."
            ],
            tags: ["anxiety"]
        ),
        TaggedPrayer(
            id: "lp-anxiety-4",
            title: "For tomorrow's weight",
            paragraphs: [
                "Lord, tomorrow has not happened yet, and I have already carried it across the whole of today. You said each day has trouble enough of its own — You were right, and I keep proving it.",
                "I confess, {name}, that I have treated worry as preparation. It isn't. It's rehearsal for a play that may never open.",
                "Set down tomorrow's bag tonight. Give me today's portion and the faith to stop there. When morning comes, You will already be in it — that's enough."
            ],
            tags: ["anxiety", "anxious"]
        ),
        TaggedPrayer(
            id: "lp-presence-3",
            title: "At the dinner table",
            paragraphs: [
                "Father, the most sacred ground I will stand on today might be a dinner table. You came eating with people, and I have been scrolling next to mine.",
                "I confess, {name}, that I have been half there for the ones who love me most. They deserve my eyes, not my forehead.",
                "Tonight, let the phone sleep in another room. Give me questions instead of replies, attention instead of presence-shaped things. Let them feel the difference."
            ],
            tags: ["presence"]
        ),
        TaggedPrayer(
            id: "lp-presence-4",
            title: "For the interruption that wasn't",
            paragraphs: [
                "Lord, You have a way of dressing appointments in interruption's clothes — the neighbour, the coworker, the child tugging a sleeve. I have treated Your appointments as noise.",
                "I confess, {name}, that my schedule has been tighter than Your compassion. Loosen it.",
                "Let me take the interruption today as an invitation. Slow my hands, open my ears. Some of the best things You do in a day arrive looking like a delay."
            ],
            tags: ["presence", "discipline"]
        ),
        TaggedPrayer(
            id: "lp-discipline-3",
            title: "The small no",
            paragraphs: [
                "Father, big victories are won in small moments, and I have been scouting the horizon while the battle sits in my pocket. You honour the small no said early.",
                "I confess, {name}, that I have saved my strength for dramatic temptations and lost to the ordinary ones. Train me in the ordinary.",
                "Give me the reflex of the small no — quick, quiet, done. Let today's discipline be so uneventful that nobody notices, especially me. That's how foundations are poured."
            ],
            tags: ["discipline"]
        ),
        TaggedPrayer(
            id: "lp-discipline-4",
            title: "Rhythm, not resolve",
            paragraphs: [
                "Lord, resolve is a bonfire — bright, brief, gone by Thursday. You offer rhythm: morning after morning, mercy after mercy, a walk instead of a sprint.",
                "I confess, {name}, that I have tried to white-knuckle my way into a life. Willpower was never meant to carry this.",
                "Build the rhythm in me: same time, same table, same open word. Let the habit be so gentle I can keep it, and so deep it keeps me."
            ],
            tags: ["discipline"]
        ),
        TaggedPrayer(
            id: "lp-discipline-5",
            title: "When no one is watching",
            paragraphs: [
                "Father, You see in secret — the unseen hours, the closed tabs, the decisions nobody will ever applaud. Your eyes are the ones I have been trying to avoid, and the ones I most want.",
                "I confess, {name}, that I have saved my best behaviour for company. Let me be the same person when the door shuts.",
                "Make my private hours clean and my public self no better than the truth. That kind of integrity is heavy, but it is the only armour that doesn't gap."
            ],
            tags: ["discipline", "purity"]
        )
    ]

    // MARK: - For any morning

    private nonisolated static let general: [TaggedPrayer] = [
        TaggedPrayer(
            id: "lp-general-1",
            title: "Armour on",
            paragraphs: [
                "Father, You are the God who goes before me, and the battle ahead of me today is one You have already seen. You have never lost a war, and You are not going to start with my Tuesday.",
                "So I stand here, {name}, putting on what You have given: truth to hold me together, righteousness to cover my heart, peace under my feet, faith raised, salvation over my mind, Your Word in hand. I confess I cannot stand unarmoured, and I do not want to try.",
                "Now send me out. Into the noise and the notifications and the ordinary hours. Guard what I look at, what I listen to, and what I let in. Let this day be counted faithful."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-2",
            title: "Guard my goings",
            paragraphs: [
                "Lord, You are my keeper — the shade at my right hand, awake when I am not. You have walked me through every day of my life, and I am asking You for one more.",
                "I confess how easily I wander — small detours, small compromises, until I am somewhere I never meant to be. Guard my goings today: my eyes, my ears, my thumbs, my wandering thoughts. Build a hedge I cannot climb over in a moment of weakness.",
                "Keep me close enough to hear You all day long. When I drift, whisper. When I fall, lift. And when the evening comes, let me kneel down clean."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-3",
            title: "This day is Yours",
            paragraphs: [
                "Father, this is the day You have made, and no algorithm made it with You. Every hour of it was written by a hand that loves me.",
                "I confess I usually try to take the day from You and run it myself. Not this morning. I give You the schedule, the conversations I am dreading, the silence I am afraid of. Order my steps; I will take them.",
                "Use me today — in my home, my work, my comings and goings. Let someone see a little of You in how present I am, how patient, how free. And keep me from the shortcuts that steal it all."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-4",
            title: "Send me out",
            paragraphs: [
                "God, You are the One who equips the called, and You have called me to today. Not to a highlight reel — to a real day, with real weight and real mercy in it.",
                "I confess I have wanted an easier life more than a faithful one. Forgive me. Whatever this day holds, I will hold on to You. When the pull comes, I pray before I scroll. When the quiet comes, I stay in it long enough to hear You.",
                "So send me out now — armoured, attended, and awake. Go with me into every room, and bring me home tonight with nothing to hide."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-5",
            title: "Before anything beeps",
            paragraphs: [
                "Father, this day will make its demands soon enough. For these few minutes, nothing beeps, nothing asks, nothing needs me but You. I am taking the better portion.",
                "I confess I have started a hundred days on other people's priorities before my own soul had a voice. Today it speaks first, {name}, and it speaks to You.",
                "Arm me in the quiet so the noise can't un-arm me. Truth at the waist, faith in the hand, salvation over the mind. Send me into the day already standing."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-6",
            title: "For the war I can't see",
            paragraphs: [
                "Lord, most of my battles are fought in rooms I cannot enter, against enemies I cannot see. You see all of it plainly, and You never once pace the sidelines.",
                "I confess, {name}, that I have fought the visible and ignored the real. Open my eyes to the actual war, and close my hand around the actual weapon.",
                "Fight what I cannot see. Guard what I cannot reach. And let me trust the watchfulness I wake up to every morning, whether or not I ever get proof."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-7",
            title: "A day with nothing spectacular",
            paragraphs: [
                "Father, today holds no mountains. Just work, people, food, traffic, sleep. You walked through ordinary days too — thirty years of them — and called every one faithful.",
                "I confess, {name}, that I have treated uneventful days as days off from holiness. The guard doesn't take days off, and neither does grace.",
                "Let me do the ordinary things today extraordinarily attended — with You beside me in each one. The discipline of plain days is what the spectacular days stand on."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-8",
            title: "Guard my thumbs",
            paragraphs: [
                "Lord, my thumbs will do more damage or more good today than my whole doctrine. They open doors faster than my heart can vet them. You know it; I know it; now let me live like it.",
                "I confess, {name}, that I have handed my mornings to whatever my thumb found first. Reclaim the first touch.",
                "Let my hands be Yours today — quick to pray, slow to scroll, ready to serve. When they reach for the phone, let them find Your word first, even for a minute. Especially for a minute."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-9",
            title: "For the face in the mirror",
            paragraphs: [
                "Father, the hardest person to forgive looks back at me from the mirror some mornings. You have already handled that whole case — the verdict was mercy, delivered at cost.",
                "I confess, {name}, that I keep reopening a case You closed. I will stop. Today I let the verdict stand.",
                "Let me look myself in the eye this morning as Yours — bought, covered, commissioned. And send me out to live like someone whose past no longer runs the show."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-10",
            title: "The last scroll of the night",
            paragraphs: [
                "Lord, the day ends the way it began: with a hand reaching for a screen. You offer a better ending — quiet, watched over, held.",
                "I confess, {name}, that I have fallen asleep to strangers instead of to Your peace more nights than I can count.",
                "Tonight, be the last voice. Let my last thought be truth and my first thought tomorrow be mercy. You keep watch while I sleep — teach me to let You."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-11",
            title: "For the ones still stuck",
            paragraphs: [
                "Father, I am not the only one fighting this fight in the dark. Somewhere tonight someone is on round four hundred, ashamed, convinced it's hopeless. I have sat in that chair.",
                "I confess, {name}, that I have prayed for my own freedom far more than for theirs. Widen my prayer tonight.",
                "Rescue the stuck ones. Use my story where it helps, and my silence where it doesn't. And make me the kind of person whose freedom makes others brave."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-12",
            title: "Small faithfulness",
            paragraphs: [
                "Father, You built the world with words and rebuild lives with days — small, repeated, unglamorous days. I keep asking You for a breakthrough when You are offering me a rhythm.",
                "I confess, {name}, that I despise the day of small things. You don't. You plant forests with seeds that fit in a pocket.",
                "Make me faithful in the small today: the small no, the small yes, the small prayer said on time. Lay one more brick, and let me trust You with the house."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-13",
            title: "For a clean ending",
            paragraphs: [
                "Lord, before this day closes, I want to stand in the evening the way I stood in the morning — armoured, honest, Yours. Nothing hidden, nothing half-surrendered.",
                "I confess, {name}, that I have ended too many days in drift, scrolling past the point where I meant to kneel.",
                "Bring me home tonight with a clean ending. Guard the hours between now and sleep. And if I fail in them, let failure send me running to You, not away — that, too, is armour."
            ],
            tags: ["general"]
        ),
        TaggedPrayer(
            id: "lp-general-14",
            title: "Everything I need",
            paragraphs: [
                "Father, You have already given me everything I need for a godly life — every piece, every promise, every power. The armour is not on layaway. It is in the closet, and You are holding the door.",
                "I confess, {name}, that I have prayed for more while wearing less than I was given. No more. Today I put on what is already mine.",
                "Buckle truth, lift faith, take the sword. Send me out dressed by You, and bring me home standing. This is the day — let me live it armoured."
            ],
            tags: ["general"]
        )
    ]

    nonisolated static let all: [TaggedPrayer] = byMood + byReason + general
}
