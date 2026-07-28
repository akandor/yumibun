package com.toepper.rocks.yumibun.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Maps the iOS SF Symbol names carried in the catalog to the closest Material icon.
 * Unmapped symbols fall back to a generic waveform.
 */
fun iconForSymbol(symbol: String): ImageVector = when (symbol) {
    // Categories
    "tree.fill" -> Icons.Filled.Forest
    "cloud.rain.fill" -> Icons.Filled.Grain
    "pawprint.fill" -> Icons.Filled.Pets
    "building.2.fill" -> Icons.Filled.Apartment
    "mappin.and.ellipse" -> Icons.Filled.Place
    "car.fill" -> Icons.Filled.DirectionsCar
    "lightbulb.fill" -> Icons.Filled.Lightbulb
    "waveform" -> Icons.Filled.GraphicEq
    // Nature
    "water.waves" -> Icons.Filled.Waves
    "flame.fill" -> Icons.Filled.LocalFireDepartment
    "wind" -> Icons.Filled.Air
    "drop.fill" -> Icons.Filled.WaterDrop
    "snowflake" -> Icons.Filled.AcUnit
    "leaf.fill" -> Icons.Filled.Eco
    "mountain.2.fill" -> Icons.Filled.Terrain
    // Rain
    "cloud.drizzle.fill" -> Icons.Filled.Grain
    "cloud.heavyrain.fill" -> Icons.Filled.Grain
    "cloud.bolt.rain.fill" -> Icons.Filled.Thunderstorm
    "window.vertical.closed" -> Icons.Filled.Window
    "umbrella.fill" -> Icons.Filled.Umbrella
    "tent.fill" -> Icons.Filled.Cabin
    // Animals
    "bird.fill" -> Icons.Filled.FlutterDash
    "ant.fill" -> Icons.Filled.BugReport
    "cat.fill" -> Icons.Filled.Pets
    "dog.fill" -> Icons.Filled.Pets
    "hare.fill" -> Icons.Filled.CrueltyFree
    "fish.fill" -> Icons.Filled.Water
    // Urban
    "road.lanes" -> Icons.Filled.Route
    "cross.case.fill" -> Icons.Filled.LocalHospital
    "figure.walk" -> Icons.Filled.DirectionsWalk
    "person.3.fill" -> Icons.Filled.Groups
    "car.2.fill" -> Icons.Filled.Traffic
    "sparkles" -> Icons.Filled.AutoAwesome
    // Places
    "cup.and.saucer.fill" -> Icons.Filled.LocalCafe
    "airplane" -> Icons.Filled.Flight
    "building.columns.fill" -> Icons.Filled.AccountBalance
    "hammer.fill" -> Icons.Filled.Construction
    "wineglass.fill" -> Icons.Filled.WineBar
    "moon.stars.fill" -> Icons.Filled.NightsStay
    "tram.fill" -> Icons.Filled.Tram
    "briefcase.fill" -> Icons.Filled.Work
    "cart.fill" -> Icons.Filled.ShoppingCart
    "figure.play" -> Icons.Filled.Attractions
    "flask.fill" -> Icons.Filled.Science
    "washer.fill" -> Icons.Filled.LocalLaundryService
    "fork.knife" -> Icons.Filled.Restaurant
    "books.vertical.fill" -> Icons.Filled.MenuBook
    // Transport
    "sailboat.fill" -> Icons.Filled.DirectionsBoat
    // Things
    "keyboard.fill" -> Icons.Filled.Keyboard
    "text.cursor" -> Icons.Filled.Keyboard
    "doc.fill" -> Icons.Filled.Description
    "clock.fill" -> Icons.Filled.Schedule
    "circle.circle.fill" -> Icons.Filled.Adjust
    "fan.fill" -> Icons.Filled.Toys
    "dryer.fill" -> Icons.Filled.LocalLaundryService
    "photo.stack.fill" -> Icons.Filled.PhotoLibrary
    "drop.degreesign.fill" -> Icons.Filled.Thermostat
    "bubbles.and.sparkles.fill" -> Icons.Filled.AutoAwesome
    "radio.fill" -> Icons.Filled.Radio
    "dot.radiowaves.left.and.right" -> Icons.Filled.Sensors
    "washing-machine" -> Icons.Filled.LocalLaundryService
    "opticaldisc.fill" -> Icons.Filled.Album
    "car.window.right" -> Icons.Filled.DirectionsCar
    else -> Icons.Filled.GraphicEq
}
