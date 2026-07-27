import Foundation

/// One playable loop. `file`/`ext` resolve against the app bundle, where the
/// synchronized Sounds group flattens every audio file to the bundle root.
struct Sound: Identifiable, Hashable {
    let id: String
    let labelKey: String
    let file: String
    let ext: String
    let symbol: String
    /// Set once at catalog build time; see SoundCatalog.categories.
    fileprivate(set) var categoryID: String = ""
    
    var label: String { LanguageSettings.localized(labelKey) }
    var url: URL? { Bundle.main.url(forResource: file, withExtension: ext) }
}

struct Category: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let symbol: String
    let sounds: [Sound]

    var title: String { LanguageSettings.localized(titleKey) }
    /// Bundled artwork basename; see ATTRIBUTION.md.
    var artworkName: String { id }
}

enum SoundCatalog {
    private static let rawCategories: [Category] = [
        Category(
            id: "nature",
            titleKey: "Nature",
            symbol: "tree.fill",
            sounds: [
            Sound(id: "river", labelKey: "River", file: "river", ext: "mp3", symbol: "water.waves"),
            Sound(id: "waves", labelKey: "Waves", file: "waves", ext: "mp3", symbol: "water.waves"),
            Sound(id: "campfire", labelKey: "Campfire", file: "campfire", ext: "mp3", symbol: "flame.fill"),
            Sound(id: "wind", labelKey: "Wind", file: "wind", ext: "mp3", symbol: "wind"),
            Sound(id: "howling-wind", labelKey: "Howling Wind", file: "howling-wind", ext: "mp3", symbol: "wind"),
            Sound(id: "wind-in-trees", labelKey: "Wind in Trees", file: "wind-in-trees", ext: "mp3", symbol: "tree.fill"),
            Sound(id: "waterfall", labelKey: "Waterfall", file: "waterfall", ext: "mp3", symbol: "drop.fill"),
            Sound(id: "walk-in-snow", labelKey: "Walk in Snow", file: "walk-in-snow", ext: "mp3", symbol: "snowflake"),
            Sound(id: "walk-on-leaves", labelKey: "Walk on Leaves", file: "walk-on-leaves", ext: "mp3", symbol: "leaf.fill"),
            Sound(id: "walk-on-gravel", labelKey: "Walk on Gravel", file: "walk-on-gravel", ext: "mp3", symbol: "mountain.2.fill"),
            Sound(id: "droplets", labelKey: "Droplets", file: "droplets", ext: "mp3", symbol: "drop.fill"),
            Sound(id: "jungle", labelKey: "Jungle", file: "jungle", ext: "mp3", symbol: "tree.fill")
            ]
        ),
        Category(
            id: "rain",
            titleKey: "Rain",
            symbol: "cloud.rain.fill",
            sounds: [
            Sound(id: "light-rain", labelKey: "Light Rain", file: "light-rain", ext: "mp3", symbol: "cloud.drizzle.fill"),
            Sound(id: "heavy-rain", labelKey: "Heavy Rain", file: "heavy-rain", ext: "mp3", symbol: "cloud.heavyrain.fill"),
            Sound(id: "thunder", labelKey: "Thunder", file: "thunder", ext: "mp3", symbol: "cloud.bolt.rain.fill"),
            Sound(id: "rain-on-window", labelKey: "Rain on Window", file: "rain-on-window", ext: "mp3", symbol: "window.vertical.closed"),
            Sound(id: "rain-on-car-roof", labelKey: "Rain on Car Roof", file: "rain-on-car-roof", ext: "mp3", symbol: "car.fill"),
            Sound(id: "rain-on-umbrella", labelKey: "Rain on Umbrella", file: "rain-on-umbrella", ext: "mp3", symbol: "umbrella.fill"),
            Sound(id: "rain-on-tent", labelKey: "Rain on Tent", file: "rain-on-tent", ext: "mp3", symbol: "tent.fill"),
            Sound(id: "rain-on-leaves", labelKey: "Rain on Leaves", file: "rain-on-leaves", ext: "mp3", symbol: "leaf.fill")
            ]
        ),
        Category(
            id: "animals",
            titleKey: "Animals",
            symbol: "pawprint.fill",
            sounds: [
            Sound(id: "birds", labelKey: "Birds", file: "birds", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "seagulls", labelKey: "Seagulls", file: "seagulls", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "crickets", labelKey: "Crickets", file: "crickets", ext: "mp3", symbol: "ant.fill"),
            Sound(id: "wolf", labelKey: "Wolf", file: "wolf", ext: "mp3", symbol: "pawprint.fill"),
            Sound(id: "owl", labelKey: "Owl", file: "owl", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "frog", labelKey: "Frog", file: "frog", ext: "mp3", symbol: "pawprint.fill"),
            Sound(id: "dog-barking", labelKey: "Dog Barking", file: "dog-barking", ext: "mp3", symbol: "dog.fill"),
            Sound(id: "horse-gallop", labelKey: "Horse Gallop", file: "horse-gallop", ext: "mp3", symbol: "hare.fill"),
            Sound(id: "cat-purring", labelKey: "Cat Purring", file: "cat-purring", ext: "mp3", symbol: "cat.fill"),
            Sound(id: "crows", labelKey: "Crows", file: "crows", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "whale", labelKey: "Whale", file: "whale", ext: "mp3", symbol: "fish.fill"),
            Sound(id: "beehive", labelKey: "Beehive", file: "beehive", ext: "mp3", symbol: "ant.fill"),
            Sound(id: "woodpecker", labelKey: "Woodpecker", file: "woodpecker", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "chickens", labelKey: "Chickens", file: "chickens", ext: "mp3", symbol: "bird.fill"),
            Sound(id: "cows", labelKey: "Cows", file: "cows", ext: "mp3", symbol: "pawprint.fill"),
            Sound(id: "sheep", labelKey: "Sheep", file: "sheep", ext: "mp3", symbol: "pawprint.fill")
            ]
        ),
        Category(
            id: "urban",
            titleKey: "Urban",
            symbol: "building.2.fill",
            sounds: [
            Sound(id: "highway", labelKey: "Highway", file: "highway", ext: "mp3", symbol: "road.lanes"),
            Sound(id: "road", labelKey: "Road", file: "road", ext: "mp3", symbol: "road.lanes"),
            Sound(id: "ambulance-siren", labelKey: "Ambulance Siren", file: "ambulance-siren", ext: "mp3", symbol: "cross.case.fill"),
            Sound(id: "busy-street", labelKey: "Busy Street", file: "busy-street", ext: "mp3", symbol: "figure.walk"),
            Sound(id: "crowd", labelKey: "Crowd", file: "crowd", ext: "mp3", symbol: "person.3.fill"),
            Sound(id: "traffic", labelKey: "Traffic", file: "traffic", ext: "mp3", symbol: "car.2.fill"),
            Sound(id: "fireworks", labelKey: "Fireworks", file: "fireworks", ext: "mp3", symbol: "sparkles")
            ]
        ),
        Category(
            id: "places",
            titleKey: "Places",
            symbol: "mappin.and.ellipse",
            sounds: [
            Sound(id: "cafe", labelKey: "Cafe", file: "cafe", ext: "mp3", symbol: "cup.and.saucer.fill"),
            Sound(id: "airport", labelKey: "Airport", file: "airport", ext: "mp3", symbol: "airplane"),
            Sound(id: "church", labelKey: "Church", file: "church", ext: "mp3", symbol: "building.columns.fill"),
            Sound(id: "temple", labelKey: "Temple", file: "temple", ext: "mp3", symbol: "building.columns.fill"),
            Sound(id: "construction-site", labelKey: "Construction Site", file: "construction-site", ext: "mp3", symbol: "hammer.fill"),
            Sound(id: "underwater", labelKey: "Underwater", file: "underwater", ext: "mp3", symbol: "water.waves"),
            Sound(id: "crowded-bar", labelKey: "Crowded Bar", file: "crowded-bar", ext: "mp3", symbol: "wineglass.fill"),
            Sound(id: "night-village", labelKey: "Night Village", file: "night-village", ext: "mp3", symbol: "moon.stars.fill"),
            Sound(id: "subway-station", labelKey: "Subway Station", file: "subway-station", ext: "mp3", symbol: "tram.fill"),
            Sound(id: "office", labelKey: "Office", file: "office", ext: "mp3", symbol: "briefcase.fill"),
            Sound(id: "supermarket", labelKey: "Supermarket", file: "supermarket", ext: "mp3", symbol: "cart.fill"),
            Sound(id: "carousel", labelKey: "Carousel", file: "carousel", ext: "mp3", symbol: "figure.play"),
            Sound(id: "laboratory", labelKey: "Laboratory", file: "laboratory", ext: "mp3", symbol: "flask.fill"),
            Sound(id: "laundry-room", labelKey: "Laundry Room", file: "laundry-room", ext: "mp3", symbol: "washer.fill"),
            Sound(id: "restaurant", labelKey: "Restaurant", file: "restaurant", ext: "mp3", symbol: "fork.knife"),
            Sound(id: "library", labelKey: "Library", file: "library", ext: "mp3", symbol: "books.vertical.fill")
            ]
        ),
        Category(
            id: "transport",
            titleKey: "Transport",
            symbol: "car.fill",
            sounds: [
            Sound(id: "train", labelKey: "Train", file: "train", ext: "mp3", symbol: "tram.fill"),
            Sound(id: "inside-a-train", labelKey: "Inside a Train", file: "inside-a-train", ext: "mp3", symbol: "tram.fill"),
            Sound(id: "airplane", labelKey: "Airplane", file: "airplane", ext: "mp3", symbol: "airplane"),
            Sound(id: "submarine", labelKey: "Submarine", file: "submarine", ext: "mp3", symbol: "water.waves"),
            Sound(id: "sailboat", labelKey: "Sailboat", file: "sailboat", ext: "mp3", symbol: "sailboat.fill"),
            Sound(id: "rowing-boat", labelKey: "Rowing Boat", file: "rowing-boat", ext: "mp3", symbol: "sailboat.fill")
            ]
        ),
        Category(
            id: "things",
            titleKey: "Things",
            symbol: "lightbulb.fill",
            sounds: [
            Sound(id: "keyboard", labelKey: "Keyboard", file: "keyboard", ext: "mp3", symbol: "keyboard.fill"),
            Sound(id: "typewriter", labelKey: "Typewriter", file: "typewriter", ext: "mp3", symbol: "text.cursor"),
            Sound(id: "paper", labelKey: "Paper", file: "paper", ext: "mp3", symbol: "doc.fill"),
            Sound(id: "clock", labelKey: "Clock", file: "clock", ext: "mp3", symbol: "clock.fill"),
            Sound(id: "wind-chimes", labelKey: "Wind Chimes", file: "wind-chimes", ext: "mp3", symbol: "wind"),
            Sound(id: "singing-bowl", labelKey: "Singing Bowl", file: "singing-bowl", ext: "mp3", symbol: "circle.circle.fill"),
            Sound(id: "ceiling-fan", labelKey: "Ceiling Fan", file: "ceiling-fan", ext: "mp3", symbol: "fan.fill"),
            Sound(id: "dryer", labelKey: "Dryer", file: "dryer", ext: "mp3", symbol: "dryer.fill"),
            Sound(id: "slide-projector", labelKey: "Slide Projector", file: "slide-projector", ext: "mp3", symbol: "photo.stack.fill"),
            Sound(id: "boiling-water", labelKey: "Boiling Water", file: "boiling-water", ext: "mp3", symbol: "drop.degreesign.fill"),
            Sound(id: "bubbles", labelKey: "Bubbles", file: "bubbles", ext: "mp3", symbol: "bubbles.and.sparkles.fill"),
            Sound(id: "tuning-radio", labelKey: "Tuning Radio", file: "tuning-radio", ext: "mp3", symbol: "radio.fill"),
            Sound(id: "morse-code", labelKey: "Morse Code", file: "morse-code", ext: "mp3", symbol: "dot.radiowaves.left.and.right"),
            Sound(id: "washing-machine", labelKey: "Washing Machine", file: "washing-machine", ext: "mp3", symbol: "washer.fill"),
            Sound(id: "vinyl-effect", labelKey: "Vinyl Effect", file: "vinyl-effect", ext: "mp3", symbol: "opticaldisc.fill"),
            Sound(id: "windshield-wipers", labelKey: "Windshield Wipers", file: "windshield-wipers", ext: "mp3", symbol: "car.window.right")
            ]
        ),
        Category(
            id: "noise",
            titleKey: "Noise",
            symbol: "waveform",
            sounds: [
            Sound(id: "white-noise", labelKey: "White Noise", file: "white-noise", ext: "wav", symbol: "waveform"),
            Sound(id: "pink-noise", labelKey: "Pink Noise", file: "pink-noise", ext: "wav", symbol: "waveform"),
            Sound(id: "brown-noise", labelKey: "Brown Noise", file: "brown-noise", ext: "wav", symbol: "waveform")
            ]
        )
    ]

    /// Stamps each sound with its owning category id.
    static let categories: [Category] = rawCategories.map { category in
        Category(
            id: category.id,
            titleKey: category.titleKey,
            symbol: category.symbol,
            sounds: category.sounds.map { sound in
                var copy = sound
                copy.categoryID = category.id
                return copy
            }
        )
    }

    static let allSounds: [Sound] = categories.flatMap(\.sounds)

    private static let byID: [String: Sound] = Dictionary(
        uniqueKeysWithValues: allSounds.map { ($0.id, $0) }
    )

    static func sound(id: String) -> Sound? { byID[id] }

    static func category(id: String) -> Category? { categories.first { $0.id == id } }
}
