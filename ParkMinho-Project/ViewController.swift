//
//  ViewController.swift
//  ParkMinho-Project
//
//  Created by Minho Park on 4/27/25.
//  Project: ParkMinho-Project
//  EID: mp52926
//  Course: CS329E

import UIKit
import Foundation

class ViewController: UIViewController, UITextFieldDelegate {
    
    // Maps each room name to the corresponding asset catalog name.
    let roomImages: [String:String] = [
        "Main Hall":     "mainhall",
        "Dining Room":   "diningroom",
        "Kitchen":       "kitchen",
        "Small Room":    "smallroom",
        "Hall A":        "halla",
        "Big Room":      "bigroom",
        "Storage":       "storage",
        "Roof Top":      "rooftop",
        "Garden":        "garden",
        "Happy Ending":  "happyending",
        "Prison":        "prison"
    ]
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var outputArea: UITextView!
    @IBOutlet weak var commandField: UITextField!
    
    override func viewDidLoad() {
            super.viewDidLoad()

            // Start with an empty output area
            outputArea.text = ""

            // Redirect all game output into the UITextView
            outputHandler = { [weak self] text in
                DispatchQueue.main.async {
                    // append the new line
                    self?.outputArea.text += text + "\n"
                    // scroll to bottom
                    let ns = self?.outputArea.text as NSString? ?? ""
                    let range = NSMakeRange(ns.length - 1, 0)
                    self?.outputArea.scrollRangeToVisible(range)
                }
            }

            // Wire up the delegate so Return key triggers our interpreter
            commandField.delegate = self

            // Load the rooms and contents, start and display
            loadGameState()
            updateImage()
        }
    
        func updateImage() {
            if let asset = roomImages[current.name],
               let img   = UIImage(named: asset) {
                imageView.image = img
            } else {
                imageView.image = nil
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard let raw = commandField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else { return false }
            let tokens = raw.components(separatedBy: " ")
            let cmd    = tokens[0].lowercased()
            let arg    = tokens.count > 1
                        ? tokens.dropFirst().joined(separator: " ")
                        : nil

            // Block all commands except reset if game ended
            if gameEnded && cmd != "reset" {
                outputHandler("\nGame is already over. Reset the game to replay.")
                commandField.text = ""
                textField.resignFirstResponder()
                return false
            }

            switch cmd {
            case "look":
                outputHandler(""); look()

            case "north", "east", "south", "west", "up", "down":
                outputHandler("")
                _ = ParkMinho_Project.move(direction: cmd)
                updateImage()

            case "inventory":
                outputHandler(""); listInventory()

            case "get":
                outputHandler("")
                if let item = arg { pickup(item) }
                else { outputHandler("Get what?") }

            case "drop":
                outputHandler("")
                if let item = arg { drop(item) }
                else { outputHandler("Drop what?") }

            case "help":
                let helpText = """
                look:\tdisplay room and contents
                north:\tmove north
                east:\tmove east
                south:\tmove south
                west:\tmove west
                up:\t\tmove up
                down:\tmove down
                inventory:\tlist carried items
                get item:\tpick up an item in the room
                drop item:\tdrop an item you’re carrying
                reset:\t\treset the game after game over or win
                help:\t\tprint this list
                exit:\t\tquit the game
                """
                outputHandler(""); outputHandler(helpText)

            case "reset":
                outputHandler(""); resetGame()
                updateImage()

            case "exit":
                outputHandler("\nThanks for playing!")
                commandField.isEnabled = false

            case "map": // debug
                outputHandler(""); displayAllRooms()

            default:
                outputHandler("\nI don’t understand that command.")
            }

            // clear & dismiss
            commandField.text = ""
            textField.resignFirstResponder()
            return false
        }

}
