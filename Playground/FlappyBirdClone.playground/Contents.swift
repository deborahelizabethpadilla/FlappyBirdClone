//: Playground - noun: a place where people can play

import SpriteKit
import PlaygroundSupport

let gameplay = GameplayScene(fileNamed: "GameplayScene")
//let gameplay = MainMenuScene(fileNamed: "MainMenuScene")
let frame = CGRect(x: 0, y: 0, width: 750, height: 1334)
let view = SKView(frame: frame)
view.presentScene(gameplay)
PlaygroundPage.current.liveView = view
PlaygroundPage.current.needsIndefiniteExecution = true