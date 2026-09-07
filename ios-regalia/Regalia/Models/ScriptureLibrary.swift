import Foundation

/// All Scripture, prayer, and renewal content used by the daily session.
nonisolated enum ScriptureLibrary {

    // MARK: - Mood-based dynamic selection

    nonisolated static func verses(for mood: Mood) -> [Verse] {
        switch mood {
        case .anxious: anxious
        case .tempted: tempted
        case .numb: numb
        case .grateful: grateful
        case .weary: weary
        }
    }

    private nonisolated static let anxious: [Verse] = [
        Verse(id: "phil4-6", text: "Do not be anxious about anything, but in every situation, by prayer and petition, present your requests to God.", reference: "Philippians 4:6"),
        Verse(id: "1pet5-7", text: "Cast all your anxiety on him because he cares for you.", reference: "1 Peter 5:7"),
        Verse(id: "isa41-10", text: "Do not fear, for I am with you; do not be dismayed, for I am your God.", reference: "Isaiah 41:10"),
        Verse(id: "ps94-19", text: "When anxiety was great within me, your consolation brought me joy.", reference: "Psalm 94:19"),
        Verse(id: "john14-27", text: "Peace I leave with you; my peace I give you. Do not let your hearts be troubled.", reference: "John 14:27")
    ]

    private nonisolated static let tempted: [Verse] = [
        Verse(id: "1cor10-13", text: "No temptation has overtaken you except what is common to mankind.", reference: "1 Corinthians 10:13"),
        Verse(id: "jas4-7", text: "Submit yourselves, then, to God. Resist the devil, and he will flee from you.", reference: "James 4:7"),
        Verse(id: "ps119-11", text: "I have hidden your word in my heart that I might not sin against you.", reference: "Psalm 119:11"),
        Verse(id: "gal5-16", text: "Walk by the Spirit, and you will not gratify the desires of the flesh.", reference: "Galatians 5:16"),
        Verse(id: "2tim2-22", text: "Flee the evil desires of youth and pursue righteousness, faith, love and peace.", reference: "2 Timothy 2:22")
    ]

    private nonisolated static let numb: [Verse] = [
        Verse(id: "eze36-26", text: "I will give you a new heart and put a new spirit in you.", reference: "Ezekiel 36:26"),
        Verse(id: "ps51-12", text: "Restore to me the joy of your salvation and grant me a willing spirit.", reference: "Psalm 51:12"),
        Verse(id: "rev2-4", text: "Yet I hold this against you: you have forsaken the love you had at first.", reference: "Revelation 2:4"),
        Verse(id: "ps42-1", text: "As the deer pants for streams of water, so my soul pants for you, my God.", reference: "Psalm 42:1"),
        Verse(id: "rom8-11", text: "The Spirit of him who raised Jesus from the dead is living in you.", reference: "Romans 8:11")
    ]

    private nonisolated static let grateful: [Verse] = [
        Verse(id: "1thes5-18", text: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.", reference: "1 Thessalonians 5:18"),
        Verse(id: "ps118-24", text: "This is the day the Lord has made; let us rejoice and be glad in it.", reference: "Psalm 118:24"),
        Verse(id: "jas1-17", text: "Every good and perfect gift is from above, coming down from the Father.", reference: "James 1:17"),
        Verse(id: "ps103-2", text: "Praise the Lord, my soul, and forget not all his benefits.", reference: "Psalm 103:2"),
        Verse(id: "col3-15", text: "Let the peace of Christ rule in your hearts… And be thankful.", reference: "Colossians 3:15")
    ]

    private nonisolated static let weary: [Verse] = [
        Verse(id: "matt11-28", text: "Come to me, all you who are weary and burdened, and I will give you rest.", reference: "Matthew 11:28"),
        Verse(id: "isa40-31", text: "Those who hope in the Lord will renew their strength. They will soar on wings like eagles.", reference: "Isaiah 40:31"),
        Verse(id: "ps28-7", text: "The Lord is my strength and my shield; my heart trusts in him, and he helps me.", reference: "Psalm 28:7"),
        Verse(id: "gal6-9", text: "Let us not become weary in doing good, for at the proper time we will reap a harvest.", reference: "Galatians 6:9"),
        Verse(id: "2cor12-9", text: "My grace is sufficient for you, for my power is made perfect in weakness.", reference: "2 Corinthians 12:9")
    ]

    // MARK: - Temptation Scripture (1 Corinthians 10:13 family)

    nonisolated static let temptation: [Verse] = [
        Verse(id: "1cor10-13-full", text: "God is faithful; he will not let you be tempted beyond what you can bear. But when you are tempted, he will also provide a way out.", reference: "1 Corinthians 10:13"),
        Verse(id: "jas1-14", text: "Each person is tempted when they are dragged away by their own evil desire and enticed.", reference: "James 1:14"),
        Verse(id: "1pet5-8", text: "Be alert and of sober mind. Your enemy the devil prowls around like a roaring lion looking for someone to devour.", reference: "1 Peter 5:8"),
        Verse(id: "matt26-41", text: "Watch and pray so that you will not fall into temptation. The spirit is willing, but the flesh is weak.", reference: "Matthew 26:41"),
        Verse(id: "heb4-15", text: "We do not have a high priest who is unable to empathize with our weaknesses… Let us then approach God's throne of grace with confidence.", reference: "Hebrews 4:15-16"),
        Verse(id: "prov4-23", text: "Above all else, guard your heart, for everything you do flows from it.", reference: "Proverbs 4:23"),
        Verse(id: "ps101-3", text: "I will not look with approval on anything that is vile.", reference: "Psalm 101:3"),
        Verse(id: "rom6-14", text: "For sin shall no longer be your master, because you are not under the law, but under grace.", reference: "Romans 6:14")
    ]

    // MARK: - Daily identity verse (non-repeating rotation)

    nonisolated static let daily: [Verse] = [
        Verse(id: "d-rom12-2", text: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.", reference: "Romans 12:2"),
        Verse(id: "d-2cor5-17", text: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", reference: "2 Corinthians 5:17"),
        Verse(id: "d-eph2-10", text: "For we are God's handiwork, created in Christ Jesus to do good works.", reference: "Ephesians 2:10"),
        Verse(id: "d-1pet2-9", text: "You are a chosen people, a royal priesthood, a holy nation, God's special possession.", reference: "1 Peter 2:9"),
        Verse(id: "d-gal2-20", text: "I have been crucified with Christ and I no longer live, but Christ lives in me.", reference: "Galatians 2:20"),
        Verse(id: "d-rom8-1", text: "Therefore, there is now no condemnation for those who are in Christ Jesus.", reference: "Romans 8:1"),
        Verse(id: "d-john1-12", text: "Yet to all who did receive him… he gave the right to become children of God.", reference: "John 1:12"),
        Verse(id: "d-ps139-14", text: "I praise you because I am fearfully and wonderfully made.", reference: "Psalm 139:14"),
        Verse(id: "d-col3-3", text: "For you died, and your life is now hidden with Christ in God.", reference: "Colossians 3:3"),
        Verse(id: "d-rom8-37", text: "In all these things we are more than conquerors through him who loved us.", reference: "Romans 8:37"),
        Verse(id: "d-2tim1-7", text: "For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.", reference: "2 Timothy 1:7"),
        Verse(id: "d-phil4-13", text: "I can do all this through him who gives me strength.", reference: "Philippians 4:13"),
        Verse(id: "d-eph1-4", text: "He chose us in him before the creation of the world to be holy and blameless in his sight.", reference: "Ephesians 1:4"),
        Verse(id: "d-1john3-1", text: "See what great love the Father has lavished on us, that we should be called children of God!", reference: "1 John 3:1"),
        Verse(id: "d-jer29-11", text: "For I know the plans I have for you, plans to prosper you and not to harm you.", reference: "Jeremiah 29:11"),
        Verse(id: "d-ps23-1", text: "The Lord is my shepherd, I lack nothing.", reference: "Psalm 23:1"),
        Verse(id: "d-isa43-1", text: "Do not fear, for I have redeemed you; I have summoned you by name; you are mine.", reference: "Isaiah 43:1"),
        Verse(id: "d-heb12-1", text: "Let us throw off everything that hinders and the sin that so easily entangles.", reference: "Hebrews 12:1"),
        Verse(id: "d-ps119-105", text: "Your word is a lamp for my feet, a light on my path.", reference: "Psalm 119:105"),
        Verse(id: "d-matt5-14", text: "You are the light of the world. A town built on a hill cannot be hidden.", reference: "Matthew 5:14"),
        Verse(id: "d-prov3-5", text: "Trust in the Lord with all your heart and lean not on your own understanding.", reference: "Proverbs 3:5"),
        Verse(id: "d-josh1-9", text: "Be strong and courageous. Do not be afraid; the Lord your God will be with you wherever you go.", reference: "Joshua 1:9"),
        Verse(id: "d-1cor6-19", text: "Do you not know that your bodies are temples of the Holy Spirit?", reference: "1 Corinthians 6:19"),
        Verse(id: "d-ps46-10", text: "Be still, and know that I am God.", reference: "Psalm 46:10"),
        Verse(id: "d-eph3-20", text: "Now to him who is able to do immeasurably more than all we ask or imagine.", reference: "Ephesians 3:20"),
        Verse(id: "d-lam3-23", text: "His compassions never fail. They are new every morning; great is your faithfulness.", reference: "Lamentations 3:22-23"),
        Verse(id: "d-1john4-4", text: "The one who is in you is greater than the one who is in the world.", reference: "1 John 4:4"),
        Verse(id: "d-ps37-4", text: "Take delight in the Lord, and he will give you the desires of your heart.", reference: "Psalm 37:4"),
        Verse(id: "d-col3-2", text: "Set your minds on things above, not on earthly things.", reference: "Colossians 3:2"),
        Verse(id: "d-gal5-22", text: "But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness.", reference: "Galatians 5:22"),
        Verse(id: "d-isa41-13", text: "For I am the Lord your God who takes hold of your right hand and says to you, Do not fear; I will help you.", reference: "Isaiah 41:13"),
        Verse(id: "d-ps121-2", text: "My help comes from the Lord, the Maker of heaven and earth.", reference: "Psalm 121:2"),
        Verse(id: "d-zeph3-17", text: "The Lord your God is with you, the Mighty Warrior who saves. In his love he will rejoice over you with singing.", reference: "Zephaniah 3:17"),
        Verse(id: "d-phil1-6", text: "He who began a good work in you will carry it on to completion until the day of Christ Jesus.", reference: "Philippians 1:6"),
        Verse(id: "d-rom8-28", text: "In all things God works for the good of those who love him, who have been called according to his purpose.", reference: "Romans 8:28"),
        Verse(id: "d-isa40-8", text: "The grass withers and the flowers fall, but the word of our God endures forever.", reference: "Isaiah 40:8"),
        Verse(id: "d-ps46-1", text: "God is our refuge and strength, an ever-present help in trouble.", reference: "Psalm 46:1"),
        Verse(id: "d-2cor4-16", text: "Though outwardly we are wasting away, yet inwardly we are being renewed day by day.", reference: "2 Corinthians 4:16"),
        Verse(id: "d-eph2-8", text: "For it is by grace you have been saved, through faith — and this is not from yourselves, it is the gift of God.", reference: "Ephesians 2:8"),
        Verse(id: "d-ps27-1", text: "The Lord is my light and my salvation — whom shall I fear? The Lord is the stronghold of my life — of whom shall I be afraid?", reference: "Psalm 27:1"),
        Verse(id: "d-isa54-17", text: "No weapon forged against you will prevail, and you will refute every tongue that accuses you.", reference: "Isaiah 54:17"),
        Verse(id: "d-matt6-33", text: "Seek first his kingdom and his righteousness, and all these things will be given to you as well.", reference: "Matthew 6:33"),
        Verse(id: "d-john8-36", text: "So if the Son sets you free, you will be free indeed.", reference: "John 8:36"),
        Verse(id: "d-2cor5-20", text: "We are therefore Christ's ambassadors, as though God were making his appeal through us.", reference: "2 Corinthians 5:20"),
        Verse(id: "d-ps18-2", text: "The Lord is my rock, my fortress and my deliverer; my God is my rock, in whom I take refuge.", reference: "Psalm 18:2"),
        Verse(id: "d-rom10-11", text: "Anyone who believes in him will never be put to shame.", reference: "Romans 10:11"),
        Verse(id: "d-heb13-5", text: "Never will I leave you; never will I forsake you.", reference: "Hebrews 13:5"),
        Verse(id: "d-james1-12", text: "Blessed is the one who perseveres under trial because, having stood the test, that person will receive the crown of life.", reference: "James 1:12"),
        Verse(id: "d-1cor15-57", text: "Thanks be to God! He gives us the victory through our Lord Jesus Christ.", reference: "1 Corinthians 15:57"),
        Verse(id: "d-rev12-11", text: "They triumphed over him by the blood of the Lamb and by the word of their testimony.", reference: "Revelation 12:11"),
        Verse(id: "d-ps119-9", text: "How can a young person stay on the path of purity? By living according to your word.", reference: "Psalm 119:9"),
        Verse(id: "d-titus2-11", text: "The grace of God has appeared that offers salvation to all people.", reference: "Titus 2:11"),
        Verse(id: "d-rom6-11", text: "Count yourselves dead to sin but alive to God in Christ Jesus.", reference: "Romans 6:11"),
        Verse(id: "d-gal5-1", text: "It is for freedom that Christ has set us free. Stand firm, then, and do not let yourselves be burdened again.", reference: "Galatians 5:1"),
        Verse(id: "d-1cor16-13", text: "Be on your guard; stand firm in the faith; be courageous; be strong.", reference: "1 Corinthians 16:13"),
        Verse(id: "d-eph6-10", text: "Be strong in the Lord and in his mighty power.", reference: "Ephesians 6:10"),
        Verse(id: "d-ps34-8", text: "Taste and see that the Lord is good; blessed is the one who takes refuge in him.", reference: "Psalm 34:8"),
        Verse(id: "d-ps34-18", text: "The Lord is close to the brokenhearted and saves those who are crushed in spirit.", reference: "Psalm 34:18"),
        Verse(id: "d-isa43-18", text: "Forget the former things; do not dwell on the past. See, I am doing a new thing!", reference: "Isaiah 43:18-19"),
        Verse(id: "d-mic6-8", text: "Act justly, love mercy, walk humbly with your God.", reference: "Micah 6:8"),
        Verse(id: "d-prov18-10", text: "The name of the Lord is a fortified tower; the righteous run to it and are safe.", reference: "Proverbs 18:10"),
        Verse(id: "d-ps62-6", text: "Truly he is my rock and my salvation; he is my fortress, I will not be shaken.", reference: "Psalm 62:6"),
        Verse(id: "d-john15-5", text: "I am the vine; you are the branches. If you remain in me and I in you, you will bear much fruit.", reference: "John 15:5"),
        Verse(id: "d-1john2-17", text: "The world and its desires pass away, but whoever does the will of God lives forever.", reference: "1 John 2:17"),
        Verse(id: "d-rom12-21", text: "Do not be overcome by evil, but overcome evil with good.", reference: "Romans 12:21"),
        Verse(id: "d-phil4-8", text: "Whatever is true, whatever is noble, whatever is right, whatever is pure — think about such things.", reference: "Philippians 4:8"),
        Verse(id: "d-2tim2-13", text: "If we are faithless, he remains faithful, for he cannot disown himself.", reference: "2 Timothy 2:13"),
        Verse(id: "d-heb10-23", text: "Let us hold unswervingly to the hope we profess, for he who promised is faithful.", reference: "Hebrews 10:23"),
        Verse(id: "d-1pet2-11", text: "I urge you, as foreigners and exiles, to abstain from sinful desires, which wage war against your soul.", reference: "1 Peter 2:11"),
        Verse(id: "d-ps51-10", text: "Create in me a pure heart, O God, and renew a steadfast spirit within me.", reference: "Psalm 51:10"),
        Verse(id: "d-matt5-16", text: "Let your light shine before others, that they may see your good deeds and glorify your Father in heaven.", reference: "Matthew 5:16"),
        Verse(id: "d-jer31-3", text: "I have loved you with an everlasting love; I have drawn you with unfailing kindness.", reference: "Jeremiah 31:3"),
        Verse(id: "d-isa30-21", text: "Whether you turn to the right or to the left, your ears will hear a voice behind you, saying, This is the way; walk in it.", reference: "Isaiah 30:21"),
        Verse(id: "d-prov3-6", text: "In all your ways submit to him, and he will make your paths straight.", reference: "Proverbs 3:6"),
        Verse(id: "d-ps32-8", text: "I will instruct you and teach you in the way you should go; I will counsel you with my loving eye on you.", reference: "Psalm 32:8"),
        Verse(id: "d-rom15-13", text: "May the God of hope fill you with all joy and peace as you trust in him.", reference: "Romans 15:13"),
        Verse(id: "d-eph3-17", text: "I pray that you, being rooted and established in love, may have power to grasp how wide and long and high and deep is the love of Christ.", reference: "Ephesians 3:17-18"),
        Verse(id: "d-col2-6", text: "Just as you received Christ Jesus as Lord, continue to live your lives in him, rooted and built up in him.", reference: "Colossians 2:6-7"),
        Verse(id: "d-2thes3-3", text: "But the Lord is faithful, and he will strengthen you and protect you from the evil one.", reference: "2 Thessalonians 3:3"),
        Verse(id: "d-ps138-7", text: "Though I walk in the midst of trouble, you preserve my life.", reference: "Psalm 138:7"),
        Verse(id: "d-neh8-10", text: "The joy of the Lord is your strength.", reference: "Nehemiah 8:10"),
        Verse(id: "d-hab3-19", text: "The Sovereign Lord is my strength; he makes my feet like the feet of a deer, he enables me to tread on the heights.", reference: "Habakkuk 3:19"),
        Verse(id: "d-2cor10-4", text: "The weapons we fight with are not the weapons of the world. They have divine power to demolish strongholds.", reference: "2 Corinthians 10:4"),
        Verse(id: "d-rom8-31", text: "If God is for us, who can be against us?", reference: "Romans 8:31"),
        Verse(id: "d-rom8-38", text: "Neither death nor life, neither angels nor demons, neither the present nor the future, will be able to separate us from the love of God in Christ Jesus.", reference: "Romans 8:38-39"),
        Verse(id: "d-1cor9-25", text: "Everyone who competes in the games goes into strict training. We do it to get a crown that will last forever.", reference: "1 Corinthians 9:25"),
        Verse(id: "d-1cor10-31", text: "Whatever you do, do it all for the glory of God.", reference: "1 Corinthians 10:31"),
        Verse(id: "d-col3-23", text: "Whatever you do, work at it with all your heart, as working for the Lord.", reference: "Colossians 3:23"),
        Verse(id: "d-eph5-15", text: "Be very careful, then, how you live — not as unwise but as wise, making the most of every opportunity.", reference: "Ephesians 5:15-16"),
        Verse(id: "d-ps90-12", text: "Teach us to number our days, that we may gain a heart of wisdom.", reference: "Psalm 90:12"),
        Verse(id: "d-matt11-29", text: "Take my yoke upon you and learn from me, and you will find rest for your souls.", reference: "Matthew 11:29"),
        Verse(id: "d-john14-1", text: "Do not let your hearts be troubled. You believe in God; believe also in me.", reference: "John 14:1"),
        Verse(id: "d-john10-10", text: "I have come that they may have life, and have it to the full.", reference: "John 10:10"),
        Verse(id: "d-john10-28", text: "I give them eternal life, and they shall never perish; no one will snatch them out of my hand.", reference: "John 10:28"),
        Verse(id: "d-ps23-4", text: "Even though I walk through the darkest valley, I will fear no evil, for you are with me.", reference: "Psalm 23:4"),
        Verse(id: "d-ps139-23", text: "Search me, God, and know my heart; test me and know my anxious thoughts.", reference: "Psalm 139:23-24"),
        Verse(id: "d-prov4-25", text: "Let your eyes look straight ahead; fix your gaze directly before you.", reference: "Proverbs 4:25"),
        Verse(id: "d-2cor3-17", text: "Now the Lord is the Spirit, and where the Spirit of the Lord is, there is freedom.", reference: "2 Corinthians 3:17"),
        Verse(id: "d-1john1-9", text: "If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.", reference: "1 John 1:9"),
        Verse(id: "d-rom5-8", text: "God demonstrates his own love for us in this: While we were still sinners, Christ died for us.", reference: "Romans 5:8")
    ]

    // MARK: - Renew Your Mind (Romans 12:2)

    nonisolated static let renewals: [MindRenewal] = [
        MindRenewal(id: "r-1", lie: "I am what my feed says I am.", truth: "I am hidden with Christ in God.", reference: "Colossians 3:3"),
        MindRenewal(id: "r-2", lie: "I've already failed today.", truth: "His mercies are new this morning.", reference: "Lamentations 3:22-23"),
        MindRenewal(id: "r-3", lie: "I'll never break this.", truth: "Sin is not my master; I am under grace.", reference: "Romans 6:14"),
        MindRenewal(id: "r-4", lie: "Everyone is further ahead than me.", truth: "God chose me before the world began.", reference: "Ephesians 1:4"),
        MindRenewal(id: "r-5", lie: "I need noise to feel okay.", truth: "In quietness and trust is my strength.", reference: "Isaiah 30:15"),
        MindRenewal(id: "r-6", lie: "God is disappointed in me.", truth: "There is now no condemnation for me.", reference: "Romans 8:1"),
        MindRenewal(id: "r-7", lie: "Nobody sees what this costs me.", truth: "My Father sees what is done in secret.", reference: "Matthew 6:6"),
        MindRenewal(id: "r-8", lie: "One more scroll won't matter.", truth: "Everything I do flows from a guarded heart.", reference: "Proverbs 4:23"),
        MindRenewal(id: "r-9", lie: "I'm too weak for this.", truth: "His power is made perfect in my weakness.", reference: "2 Corinthians 12:9"),
        MindRenewal(id: "r-10", lie: "I am alone in this fight.", truth: "The One in me is greater than the one in the world.", reference: "1 John 4:4"),
        MindRenewal(id: "r-11", lie: "I can't control it, so why try.", truth: "I can do all this through him who gives me strength.", reference: "Philippians 4:13"),
        MindRenewal(id: "r-12", lie: "God is far away.", truth: "He is not far from any one of us.", reference: "Acts 17:27"),
        MindRenewal(id: "r-13", lie: "I'll start tomorrow.", truth: "Now is the time of God's favour; now is the day of salvation.", reference: "2 Corinthians 6:2"),
        MindRenewal(id: "r-14", lie: "I am what I've done.", truth: "The old has gone, the new is here.", reference: "2 Corinthians 5:17"),
        MindRenewal(id: "r-15", lie: "My past disqualifies me.", truth: "He who began a good work in me will carry it on to completion.", reference: "Philippians 1:6"),
        MindRenewal(id: "r-16", lie: "I need this to relax.", truth: "He makes me lie down in green pastures; he refreshes my soul.", reference: "Psalm 23:2-3"),
        MindRenewal(id: "r-17", lie: "No one else struggles like this.", truth: "No temptation has overtaken me except what is common to mankind.", reference: "1 Corinthians 10:13"),
        MindRenewal(id: "r-18", lie: "I have to earn God's love today.", truth: "While we were still sinners, Christ died for us.", reference: "Romans 5:8"),
        MindRenewal(id: "r-19", lie: "One look won't hurt.", truth: "I made a covenant with my eyes not to look lustfully.", reference: "Job 31:1"),
        MindRenewal(id: "r-20", lie: "I'm too tired to pray.", truth: "Those who hope in the Lord will renew their strength.", reference: "Isaiah 40:31"),
        MindRenewal(id: "r-21", lie: "The silence means God left.", truth: "Never will I leave you; never will I forsake you.", reference: "Hebrews 13:5"),
        MindRenewal(id: "r-22", lie: "I keep the phone nearby just in case.", truth: "When I am afraid, I put my trust in you.", reference: "Psalm 56:3"),
        MindRenewal(id: "r-23", lie: "This app is my willpower.", truth: "My help comes from the Lord, the Maker of heaven and earth.", reference: "Psalm 121:2"),
        MindRenewal(id: "r-24", lie: "A missed day ruins everything.", truth: "Though the righteous fall seven times, they rise again.", reference: "Proverbs 24:16"),
        MindRenewal(id: "r-25", lie: "The night is when I'm weakest.", truth: "The Lord watches over you — the sun will not harm you by day, nor the moon by night.", reference: "Psalm 121:6"),
        MindRenewal(id: "r-26", lie: "I've wasted too much time to matter.", truth: "See, I am doing a new thing!", reference: "Isaiah 43:19"),
        MindRenewal(id: "r-27", lie: "My thoughts aren't safe with me.", truth: "We take every thought captive to make it obedient to Christ.", reference: "2 Corinthians 10:5"),
        MindRenewal(id: "r-28", lie: "I need to see it to believe it.", truth: "We live by faith, not by sight.", reference: "2 Corinthians 5:7"),
        MindRenewal(id: "r-29", lie: "Nobody would blame me.", truth: "Whoever can be trusted with very little can also be trusted with much.", reference: "Luke 16:10"),
        MindRenewal(id: "r-30", lie: "I have to do this alone.", truth: "The Spirit helps us in our weakness.", reference: "Romans 8:26")
    ]

    // MARK: - Supporting Scripture behind each piece of armour

    nonisolated static let supportingVerses: [ArmourPiece: [Verse]] = [
        .belt: [
            Verse(id: "s-john8-32", text: "You will know the truth, and the truth will set you free.", reference: "John 8:32"),
            Verse(id: "s-john17-17", text: "Sanctify them by the truth; your word is truth.", reference: "John 17:17"),
            Verse(id: "s-eph4-25", text: "Each of you must put off falsehood and speak truthfully to your neighbour.", reference: "Ephesians 4:25"),
            Verse(id: "s-prov30-5", text: "Every word of God is flawless; he is a shield to those who take refuge in him.", reference: "Proverbs 30:5")
        ],
        .breastplate: [
            Verse(id: "s-2cor5-21", text: "God made him who had no sin to be sin for us, so that in him we might become the righteousness of God.", reference: "2 Corinthians 5:21"),
            Verse(id: "s-isa61-10", text: "He has clothed me with garments of salvation and arrayed me in a robe of his righteousness.", reference: "Isaiah 61:10"),
            Verse(id: "s-rom3-22", text: "This righteousness is given through faith in Jesus Christ to all who believe.", reference: "Romans 3:22"),
            Verse(id: "s-phil3-9", text: "Not having a righteousness of my own… but that which is through faith in Christ.", reference: "Philippians 3:9")
        ],
        .sandals: [
            Verse(id: "s-rom5-1", text: "Since we have been justified through faith, we have peace with God through our Lord Jesus Christ.", reference: "Romans 5:1"),
            Verse(id: "s-phil4-7", text: "The peace of God, which transcends all understanding, will guard your hearts and your minds.", reference: "Philippians 4:7"),
            Verse(id: "s-isa26-3", text: "You will keep in perfect peace those whose minds are steadfast, because they trust in you.", reference: "Isaiah 26:3"),
            Verse(id: "s-john16-33", text: "In this world you will have trouble. But take heart! I have overcome the world.", reference: "John 16:33")
        ],
        .shield: [
            Verse(id: "s-heb11-1", text: "Now faith is confidence in what we hope for and assurance about what we do not see.", reference: "Hebrews 11:1"),
            Verse(id: "s-2cor5-7", text: "For we live by faith, not by sight.", reference: "2 Corinthians 5:7"),
            Verse(id: "s-1john5-4", text: "This is the victory that has overcome the world, even our faith.", reference: "1 John 5:4"),
            Verse(id: "s-ps91-4", text: "He will cover you with his feathers, and under his wings you will find refuge; his faithfulness will be your shield.", reference: "Psalm 91:4")
        ],
        .helmet: [
            Verse(id: "s-titus3-5", text: "He saved us, not because of righteous things we had done, but because of his mercy.", reference: "Titus 3:5"),
            Verse(id: "s-ps140-7", text: "Sovereign Lord, my strong deliverer, you cover my head in the day of battle.", reference: "Psalm 140:7"),
            Verse(id: "s-1thes5-9", text: "God did not appoint us to suffer wrath but to receive salvation through our Lord Jesus Christ.", reference: "1 Thessalonians 5:9"),
            Verse(id: "s-1pet1-3", text: "In his great mercy he has given us new birth into a living hope through the resurrection of Jesus Christ.", reference: "1 Peter 1:3")
        ],
        .sword: [
            Verse(id: "s-heb4-12", text: "The word of God is alive and active. Sharper than any double-edged sword.", reference: "Hebrews 4:12"),
            Verse(id: "s-matt4-4", text: "Man shall not live on bread alone, but on every word that comes from the mouth of God.", reference: "Matthew 4:4"),
            Verse(id: "s-isa55-11", text: "So is my word that goes out from my mouth: it will not return to me empty.", reference: "Isaiah 55:11"),
            Verse(id: "s-2tim3-16", text: "All Scripture is God-breathed and is useful for teaching, rebuking, correcting and training.", reference: "2 Timothy 3:16")
        ],
        .prayer: [
            Verse(id: "s-rom8-26", text: "The Spirit helps us in our weakness. We do not know what we ought to pray for, but the Spirit himself intercedes for us.", reference: "Romans 8:26"),
            Verse(id: "s-james5-16", text: "The prayer of a righteous person is powerful and effective.", reference: "James 5:16"),
            Verse(id: "s-ps62-8", text: "Trust in him at all times, you people; pour out your hearts to him, for God is our refuge.", reference: "Psalm 62:8"),
            Verse(id: "s-jer33-3", text: "Call to me and I will answer you and tell you great and unsearchable things you do not know.", reference: "Jeremiah 33:3")
        ]
    ]

    /// The supporting verse behind a piece for the given day — rotates through the
    /// piece's verse pool so the same seven steps feel new across the week.
    nonisolated static func supportingVerse(for piece: ArmourPiece, on date: Date) -> Verse? {
        guard let pool = supportingVerses[piece], !pool.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[(day - 1) % pool.count]
    }
}
