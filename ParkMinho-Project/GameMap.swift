//
//  GameMap.swift
//  ParkMinho-Project
//
//  Created by Minho Park on 4/27/25.
//  Project: ParkMinho-Project
//  EID: mp52926
//  Course: CS329E

//  room definitions, movement, inventory, and game state with persistence.

import Foundation

// Global output handler; redirect to UI TextView
var outputHandler: (String) -> Void = { print($0) }

// Global Game State
var floorPlan: [Room] = [] // All rooms
var current: Room! // Player's current room
var inventory: [String] = [] // Items carried
var gameEnded = false // True after win or loss

// Save using UserDefaults (not much information to save, so I used UserDefaults)
func saveGameState() {
    let defaults = UserDefaults.standard
    // Save current location
    defaults.set(current.name, forKey: "currentRoom")
    // Save inventory
    defaults.set(inventory, forKey: "inventory")
    // Save game ended flag
    defaults.set(gameEnded, forKey: "gameEnded")
    // Save room contents mapping
    var contentsDict: [String:[String]] = [:]
    for room in floorPlan {
        contentsDict[room.name] = room.contents
    }
    defaults.set(contentsDict, forKey: "roomContents")
}

func loadGameState() {
    let defaults = UserDefaults.standard
    // Attempt to load saved state
    guard let savedRoom = defaults.string(forKey: "currentRoom") else {
        // No saved state; start fresh
        resetGame()
        return
    }
    // Load map structure
    loadMap()
    // Restore inventory
    inventory = defaults.stringArray(forKey: "inventory") ?? []
    // Restore end flag
    gameEnded = defaults.bool(forKey: "gameEnded")
    // Restore contents
    if let savedContents = defaults.dictionary(forKey: "roomContents") as? [String:[String]] {
        for room in floorPlan {
            if let cont = savedContents[room.name] {
                room.contents = cont
            }
        }
    }
    // Restore current
    current = getRoom(savedRoom)
}

// Room Model
class Room {
    let name: String
    let north: String
    let east: String
    let south: String
    let west: String
    let up: String
    let down: String
    var contents: [String]

    init(name: String,
         north: String,
         east: String,
         south: String,
         west: String,
         up: String,
         down: String,
         contents: [String]) {
        self.name = name
        self.north = north
        self.east = east
        self.south = south
        self.west = west
        self.up = up
        self.down = down
        self.contents = contents
    }

    func displayRoom() {
        outputHandler("You are in the \(name).")
        let items = contents.filter { $0 != "None" }
        if items.isEmpty {
            outputHandler("Contents: nothing.")
        } else {
            outputHandler("Contents: " + items.joined(separator: ", "))
        }
    }
}

// Map Construction
func createRoom(_ data: [String]) -> Room {
    let items = data.count > 7 ? Array(data[7...]) : ["None"]
    return Room(name: data[0], north: data[1], east: data[2], south: data[3], west: data[4], up: data[5], down: data[6], contents: items)
}

// Castle
func loadMap() {
    let roomsData = [
        ["Main Hall","Small Room","Hall A","Garden","Dining Room","None","None","torch"],
        ["Dining Room","Kitchen","Main Hall","None","None","None","None","plate","cup","food"],
        ["Kitchen","None","Small Room","Dining Room","None","None","None","stick","knife"],
        ["Small Room","None","None","Main Hall","Kitchen","None","Prison","toy"],
        ["Prison","None","None","None","None","Small Room","None","sleeping monster"],
        ["Hall A","None","Big Room","None","Main Hall","None","None","portrait"],
        ["Big Room","None","None","None","Hall A","Roof Top","Storage","book"],
        ["Storage","None","None","None","None","Big Room","None","roof top key","main key"],
        ["Roof Top","None","None","None","None","None","Big Room","ladder"],
        ["Garden","None","None","Happy Ending","Main Hall","None","None","flower"],
        ["Happy Ending","None","None","None","None","None","None"]
    ]
    floorPlan = roomsData.map(createRoom)
}

// Game Reset
func resetGame() {
    loadMap()
    guard let start = floorPlan.first(where: { $0.name == "Main Hall" }) else { fatalError("Main Hall missing") }
    current = start
    inventory.removeAll()
    gameEnded = false
    outputHandler("Game starts. Escape from this castle.\n")
    current.displayRoom()
    saveGameState()
}

// Room Lookup
func getRoom(_ name: String) -> Room {
    if let room = floorPlan.first(where: { $0.name == name }) {
        return room
    }
    fatalError("Room named \(name) not found.")
}

// Look Command
func look() {
    guard !gameEnded else { outputHandler("\nGame is over. Reset to play again."); return }
    current.displayRoom()
    saveGameState()
}

// Inventory Commands
func pickup(_ item: String) {
    guard !gameEnded else { outputHandler("\nGame is over. Reset to play again."); return }
    let lower = item.lowercased()
    if lower == "torch" && !inventory.contains("stick") {
        outputHandler("The torch is too hot. You need a Stick to hold it.")
        return
    }
    if lower == "portrait" {
        outputHandler("The portrait’s eyes follow you. You are too spooked to take it.")
        return
    }
    if lower == "main key" && !inventory.contains("ladder") {
        outputHandler("The Main Key is out of reach. You need a Ladder.")
        return
    }
    if let idx = current.contents.firstIndex(of: item) {
        current.contents.remove(at: idx)
        inventory.append(item)
        outputHandler("Picked up: \(item)")
        saveGameState()
    } else {
        outputHandler("No such item here.")
    }
}

func drop(_ item: String) {
    guard !gameEnded else { outputHandler("\nGame is over. Reset to play again."); return }
    if let idx = inventory.firstIndex(of: item) {
        inventory.remove(at: idx)
        if current.name == "Prison" {
            if item == "food" {
                outputHandler("Monster wakes happily and gives you the Big Room Key.")
                inventory.append("big room key")
            } else {
                outputHandler("You are eaten by the monster. Game Over.")
                gameEnded = true
            }
            saveGameState()
            return
        } else {
            current.contents.append(item)
            outputHandler("Dropped: \(item)")
            saveGameState()
        }
    } else {
        outputHandler("You don’t have that.")
    }
}

func listInventory() {
    guard !gameEnded else { outputHandler("\nGame is over. Reset to play again."); return }
    if inventory.isEmpty {
        outputHandler("Inventory empty.")
    } else {
        outputHandler("Inventory: " + inventory.joined(separator: ", "))
    }
    saveGameState()
}

// Movement Command
func move(direction: String) -> Room {
    guard !gameEnded else { outputHandler("\nGame is over. Reset to play again."); return current }
    let dir = direction.lowercased()
    let dest: String = {
        switch dir {
        case "north": return current.north
        case "east":  return current.east
        case "south": return current.south
        case "west":  return current.west
        case "up":    return current.up
        case "down":  return current.down
        default:       return "None"
        }
    }()
    // Locked gate checks
    if current.name == "Hall A" && dest == "Big Room" && !inventory.contains("big room key") {
        outputHandler("The door to the Big Room is locked.")
        return current
    }
    if current.name == "Main Hall" && dest == "Garden" && !inventory.contains("main key") {
        outputHandler("The gate to the Garden is locked.")
        return current
    }
    if current.name == "Big Room" && dest == "Roof Top" && !inventory.contains("roof top key") {
        outputHandler("The hatch to the Roof Top is locked.")
        return current
    }
    // Dark storage
    if dest == "Storage" && !inventory.contains("torch") {
        outputHandler("It’s too dark in Storage. You need a Torch.")
        return current
    }
    if dest == "None" {
        outputHandler("You can’t go that way.")
        return current
    }
    let newRoom = getRoom(dest)
    current = newRoom
    if newRoom.name == "Happy Ending" {
        outputHandler("Congratulations! You’ve escaped the castle safely.")
        gameEnded = true
    } else {
        outputHandler("Moved to: \(newRoom.name)")
    }
    saveGameState()
    return newRoom
}

// Show full map cheat code for me
func displayAllRooms() {
    for room in floorPlan {
        // Room name
        outputHandler("Room name: \(room.name)")
        // Exits
        if room.north != "None" { outputHandler("\tRoom to the north: \(room.north)") }
        if room.east  != "None" { outputHandler("\tRoom to the east:  \(room.east)") }
        if room.south != "None" { outputHandler("\tRoom to the south: \(room.south)") }
        if room.west  != "None" { outputHandler("\tRoom to the west:  \(room.west)") }
        if room.up    != "None" { outputHandler("\tRoom above:        \(room.up)") }
        if room.down  != "None" { outputHandler("\tRoom below:        \(room.down)") }
        // Contents
        let items = room.contents.filter { $0 != "None" }
        if items.isEmpty {
            outputHandler("\tContents: nothing.")
        } else {
            outputHandler("\tContents: " + items.joined(separator: ", "))
        }
        outputHandler("")
    }
}
