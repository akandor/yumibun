package com.toepper.rocks.yumibun.data

/** One playable looping sound. `file`/`ext` resolve against assets/sounds/. */
data class Sound(
    val id: String,
    val labelKey: String,
    val file: String,
    val ext: String,
    val symbol: String,
    val categoryId: String,
) {
    /** Path within the app's assets. */
    val assetPath: String get() = "sounds/$file.$ext"

    /** Display label, localized from the English `labelKey` via [Loc]. */
    val label: String get() = Loc.get(labelKey)
}

data class Category(
    val id: String,
    val titleKey: String,
    val symbol: String,
    val sounds: List<Sound>,
) {
    /** Bundled artwork basename in assets/artwork/. */
    val artworkName: String get() = id

    /** Display title, localized from the English `titleKey` via [Loc]. */
    val title: String get() = Loc.get(titleKey)
}

object SoundCatalog {
    val categories: List<Category> = listOf(
        Category(
            id = "nature",
            titleKey = "Nature",
            symbol = "tree.fill",
            sounds = listOf(
                Sound("river", "River", "river", "mp3", "water.waves", "nature"),
                Sound("waves", "Waves", "waves", "mp3", "water.waves", "nature"),
                Sound("campfire", "Campfire", "campfire", "mp3", "flame.fill", "nature"),
                Sound("wind", "Wind", "wind", "mp3", "wind", "nature"),
                Sound("howling-wind", "Howling Wind", "howling-wind", "mp3", "wind", "nature"),
                Sound("wind-in-trees", "Wind in Trees", "wind-in-trees", "mp3", "tree.fill", "nature"),
                Sound("waterfall", "Waterfall", "waterfall", "mp3", "drop.fill", "nature"),
                Sound("walk-in-snow", "Walk in Snow", "walk-in-snow", "mp3", "snowflake", "nature"),
                Sound("walk-on-leaves", "Walk on Leaves", "walk-on-leaves", "mp3", "leaf.fill", "nature"),
                Sound("walk-on-gravel", "Walk on Gravel", "walk-on-gravel", "mp3", "mountain.2.fill", "nature"),
                Sound("droplets", "Droplets", "droplets", "mp3", "drop.fill", "nature"),
                Sound("jungle", "Jungle", "jungle", "mp3", "tree.fill", "nature"),
            ),
        ),
        Category(
            id = "rain",
            titleKey = "Rain",
            symbol = "cloud.rain.fill",
            sounds = listOf(
                Sound("light-rain", "Light Rain", "light-rain", "mp3", "cloud.drizzle.fill", "rain"),
                Sound("heavy-rain", "Heavy Rain", "heavy-rain", "mp3", "cloud.heavyrain.fill", "rain"),
                Sound("thunder", "Thunder", "thunder", "mp3", "cloud.bolt.rain.fill", "rain"),
                Sound("rain-on-window", "Rain on Window", "rain-on-window", "mp3", "window.vertical.closed", "rain"),
                Sound("rain-on-car-roof", "Rain on Car Roof", "rain-on-car-roof", "mp3", "car.fill", "rain"),
                Sound("rain-on-umbrella", "Rain on Umbrella", "rain-on-umbrella", "mp3", "umbrella.fill", "rain"),
                Sound("rain-on-tent", "Rain on Tent", "rain-on-tent", "mp3", "tent.fill", "rain"),
                Sound("rain-on-leaves", "Rain on Leaves", "rain-on-leaves", "mp3", "leaf.fill", "rain"),
            ),
        ),
        Category(
            id = "animals",
            titleKey = "Animals",
            symbol = "pawprint.fill",
            sounds = listOf(
                Sound("birds", "Birds", "birds", "mp3", "bird.fill", "animals"),
                Sound("seagulls", "Seagulls", "seagulls", "mp3", "bird.fill", "animals"),
                Sound("crickets", "Crickets", "crickets", "mp3", "ant.fill", "animals"),
                Sound("wolf", "Wolf", "wolf", "mp3", "pawprint.fill", "animals"),
                Sound("owl", "Owl", "owl", "mp3", "bird.fill", "animals"),
                Sound("frog", "Frog", "frog", "mp3", "pawprint.fill", "animals"),
                Sound("dog-barking", "Dog Barking", "dog-barking", "mp3", "dog.fill", "animals"),
                Sound("horse-gallop", "Horse Gallop", "horse-gallop", "mp3", "hare.fill", "animals"),
                Sound("cat-purring", "Cat Purring", "cat-purring", "mp3", "cat.fill", "animals"),
                Sound("crows", "Crows", "crows", "mp3", "bird.fill", "animals"),
                Sound("whale", "Whale", "whale", "mp3", "fish.fill", "animals"),
                Sound("beehive", "Beehive", "beehive", "mp3", "ant.fill", "animals"),
                Sound("woodpecker", "Woodpecker", "woodpecker", "mp3", "bird.fill", "animals"),
                Sound("chickens", "Chickens", "chickens", "mp3", "bird.fill", "animals"),
                Sound("cows", "Cows", "cows", "mp3", "pawprint.fill", "animals"),
                Sound("sheep", "Sheep", "sheep", "mp3", "pawprint.fill", "animals"),
            ),
        ),
        Category(
            id = "urban",
            titleKey = "Urban",
            symbol = "building.2.fill",
            sounds = listOf(
                Sound("highway", "Highway", "highway", "mp3", "road.lanes", "urban"),
                Sound("road", "Road", "road", "mp3", "road.lanes", "urban"),
                Sound("ambulance-siren", "Ambulance Siren", "ambulance-siren", "mp3", "cross.case.fill", "urban"),
                Sound("busy-street", "Busy Street", "busy-street", "mp3", "figure.walk", "urban"),
                Sound("crowd", "Crowd", "crowd", "mp3", "person.3.fill", "urban"),
                Sound("traffic", "Traffic", "traffic", "mp3", "car.2.fill", "urban"),
                Sound("fireworks", "Fireworks", "fireworks", "mp3", "sparkles", "urban"),
            ),
        ),
        Category(
            id = "places",
            titleKey = "Places",
            symbol = "mappin.and.ellipse",
            sounds = listOf(
                Sound("cafe", "Cafe", "cafe", "mp3", "cup.and.saucer.fill", "places"),
                Sound("airport", "Airport", "airport", "mp3", "airplane", "places"),
                Sound("church", "Church", "church", "mp3", "building.columns.fill", "places"),
                Sound("temple", "Temple", "temple", "mp3", "building.columns.fill", "places"),
                Sound("construction-site", "Construction Site", "construction-site", "mp3", "hammer.fill", "places"),
                Sound("underwater", "Underwater", "underwater", "mp3", "water.waves", "places"),
                Sound("crowded-bar", "Crowded Bar", "crowded-bar", "mp3", "wineglass.fill", "places"),
                Sound("night-village", "Night Village", "night-village", "mp3", "moon.stars.fill", "places"),
                Sound("subway-station", "Subway Station", "subway-station", "mp3", "tram.fill", "places"),
                Sound("office", "Office", "office", "mp3", "briefcase.fill", "places"),
                Sound("supermarket", "Supermarket", "supermarket", "mp3", "cart.fill", "places"),
                Sound("carousel", "Carousel", "carousel", "mp3", "figure.play", "places"),
                Sound("laboratory", "Laboratory", "laboratory", "mp3", "flask.fill", "places"),
                Sound("laundry-room", "Laundry Room", "laundry-room", "mp3", "washer.fill", "places"),
                Sound("restaurant", "Restaurant", "restaurant", "mp3", "fork.knife", "places"),
                Sound("library", "Library", "library", "mp3", "books.vertical.fill", "places"),
            ),
        ),
        Category(
            id = "transport",
            titleKey = "Transport",
            symbol = "car.fill",
            sounds = listOf(
                Sound("train", "Train", "train", "mp3", "tram.fill", "transport"),
                Sound("inside-a-train", "Inside a Train", "inside-a-train", "mp3", "tram.fill", "transport"),
                Sound("airplane", "Airplane", "airplane", "mp3", "airplane", "transport"),
                Sound("submarine", "Submarine", "submarine", "mp3", "water.waves", "transport"),
                Sound("sailboat", "Sailboat", "sailboat", "mp3", "sailboat.fill", "transport"),
                Sound("rowing-boat", "Rowing Boat", "rowing-boat", "mp3", "sailboat.fill", "transport"),
            ),
        ),
        Category(
            id = "things",
            titleKey = "Things",
            symbol = "lightbulb.fill",
            sounds = listOf(
                Sound("keyboard", "Keyboard", "keyboard", "mp3", "keyboard.fill", "things"),
                Sound("typewriter", "Typewriter", "typewriter", "mp3", "text.cursor", "things"),
                Sound("paper", "Paper", "paper", "mp3", "doc.fill", "things"),
                Sound("clock", "Clock", "clock", "mp3", "clock.fill", "things"),
                Sound("wind-chimes", "Wind Chimes", "wind-chimes", "mp3", "wind", "things"),
                Sound("singing-bowl", "Singing Bowl", "singing-bowl", "mp3", "circle.circle.fill", "things"),
                Sound("ceiling-fan", "Ceiling Fan", "ceiling-fan", "mp3", "fan.fill", "things"),
                Sound("dryer", "Dryer", "dryer", "mp3", "dryer.fill", "things"),
                Sound("slide-projector", "Slide Projector", "slide-projector", "mp3", "photo.stack.fill", "things"),
                Sound("boiling-water", "Boiling Water", "boiling-water", "mp3", "drop.degreesign.fill", "things"),
                Sound("bubbles", "Bubbles", "bubbles", "mp3", "bubbles.and.sparkles.fill", "things"),
                Sound("tuning-radio", "Tuning Radio", "tuning-radio", "mp3", "radio.fill", "things"),
                Sound("morse-code", "Morse Code", "morse-code", "mp3", "dot.radiowaves.left.and.right", "things"),
                Sound("washing-machine", "Washing Machine", "washing-machine", "mp3", "washer.fill", "things"),
                Sound("vinyl-effect", "Vinyl Effect", "vinyl-effect", "mp3", "opticaldisc.fill", "things"),
                Sound("windshield-wipers", "Windshield Wipers", "windshield-wipers", "mp3", "car.window.right", "things"),
            ),
        ),
        Category(
            id = "noise",
            titleKey = "Noise",
            symbol = "waveform",
            sounds = listOf(
                Sound("white-noise", "White Noise", "white-noise", "wav", "waveform", "noise"),
                Sound("pink-noise", "Pink Noise", "pink-noise", "wav", "waveform", "noise"),
                Sound("brown-noise", "Brown Noise", "brown-noise", "wav", "waveform", "noise"),
            ),
        ),
    )

    val allSounds: List<Sound> = categories.flatMap { it.sounds }
    private val byId: Map<String, Sound> = allSounds.associateBy { it.id }
    fun sound(id: String): Sound? = byId[id]
    fun category(id: String): Category? = categories.firstOrNull { it.id == id }
}
