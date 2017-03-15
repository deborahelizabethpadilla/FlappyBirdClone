//
//  GameplayScene.swift
//  FlappyBirdClone
//
//  Created by Deborah on 1/9/17.
//  Copyright © 2017 Deborah. All rights reserved.
//

import SpriteKit
import Speech
import AVFoundation

public class GameplayScene: SKScene, SKPhysicsContactDelegate, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder!
    var recordingSession: AVAudioSession!
    var timer: Timer!

    
    var bird = Bird();
    
    var pipesHolder = SKNode();
    
    var scoreLabel = SKLabelNode(/*fontNamed: "04b_19"*/);
    
    var score = 0;
    
    var gameStarted = false;
    var isAlive = false;
    
    var press = SKSpriteNode()
    
    public override func sceneDidLoad() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Record permission granted")
                    } else {
                        print("Record permission not granted")
                    }
                }
            }
        } catch {
        }
    }
    
    override public func didMove(to view: SKView) {
        initalize();
    }
    
    override public func update(_ currentTime: TimeInterval) {
        if isAlive {
            moveBackgroundsAndGrounds();
        }
    }
        
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //First Time We Touch The Screen
        if gameStarted == false {
            isAlive = true;
            gameStarted = true;
            press.removeFromParent();
            spawnObstacles();
            bird.physicsBody?.affectedByGravity = true
            bird.flap()
        }
        
        if isAlive {
            bird.flap();
        }
        
        for touch in touches {
            let location = touch.location(in: self);
            
            if atPoint(location).name == "Retry" {
                //Restart The Game
                self.removeAllActions();
                self.removeAllChildren();
                initalize();
            }
            
            if atPoint(location).name == "Quit" {
                let mainMenu = MainMenuScene(fileNamed: "MainMenuScene");
                mainMenu?.scaleMode = .aspectFill
                self.view?.presentScene(mainMenu!, transition: SKTransition.doorway(withDuration: TimeInterval(1)));
            }
        }
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody();
        var secondBody = SKPhysicsBody();
        
        if contact.bodyA.node?.name == "Bird" {
            firstBody = contact.bodyA;
            secondBody = contact.bodyB;
        } else {
            firstBody = contact.bodyB;
            secondBody = contact.bodyA;
        }
        
        if firstBody.node?.name == "Bird" && secondBody.node?.name == "Score" {
            incrementScore();
        } else if firstBody.node?.name == "Bird" && secondBody.node?.name == "Pipe" {
            
            if isAlive {
                birdDied();
            }
            
        } else if firstBody.node?.name == "Bird" && secondBody.node?.name == "Ground" {
            
            if isAlive {
                birdDied();
            }
        }
    }
    
    var oldPeak: Float = 0;
    func initalize() {
//        try! AppDelegate.mySelf.startRecording(callback: callback)
        gameStarted = false;
        isAlive = false;
        score = 0;
        
        physicsWorld.contactDelegate = self;
        
        createInstructions();
        createBird();
        createBackgrounds();
        createGrounds();
        createLabel();
        
        oldPeak = 0
        self.startRecording { peak in
            let oldVal = self.oldPeak
            self.oldPeak = pow(10, (0.05 * peak));
            
            print("Val = \(self.oldPeak)")
            guard self.oldPeak >= 0.12, abs(oldVal - self.oldPeak) >= 0.008, self.isAlive else {
                return
            }
            
            self.bird.flap()
            print("=============\(self.oldPeak)")
        }
    }
    
    func createInstructions() {
        press = SKSpriteNode(imageNamed: "Press");
        press.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        press.position = CGPoint(x: 0, y: 0);
        press.setScale(1.8);
        press.zPosition = 10;
        self.addChild(press);
    }
    
    func createBird() {
        bird = Bird(imageNamed: "\(GameManager.instance.getBird()) 1");
        bird.initalize();
        bird.position = CGPoint(x: -50, y: 0);
        self.addChild(bird);
    }
    
    func createBackgrounds() {
        for i in 0...2 {
            let bg = SKSpriteNode(imageNamed: "BG Day");
            bg.name = "BG";
            bg.zPosition = 0;
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5);
            bg.position = CGPoint(x: CGFloat(i) * bg.size.width, y: 0);
            self.addChild(bg);
            
        }
    }
    
    func createGrounds() {
        for i in 0...2 {
            let ground = SKSpriteNode(imageNamed: "Ground");
            ground.name = "Ground";
            ground.zPosition = 4;
            ground.anchorPoint = CGPoint(x: 0.5, y: 0.5);
            ground.position = CGPoint(x: CGFloat(i) * ground.size.width, y: -(self.frame.size.height / 2));
            self.addChild(ground);
            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size);
            ground.physicsBody?.affectedByGravity = false;
            ground.physicsBody?.isDynamic = false;
            ground.physicsBody?.categoryBitMask = ColliderType.Ground;
        }
    }
    
    func moveBackgroundsAndGrounds() {
        enumerateChildNodes(withName: "BG", using: ({
            (node, error) in
            
            node.position.x -= 4.5;
            if node.position.x < -(self.frame.width) {
                node.position.x += self.frame.width * 3;
            }
        }));
        
        func moveBackgroundsAndGrounds() {
            enumerateChildNodes(withName: "Ground", using: ({
                (node, error) in
                
                node.position.x -= 2;
                if node.position.x < -(self.frame.width) {
                    node.position.x += self.frame.width * 3;
                }
            }));
        }
        
    }
    
    func createPipes() {
        pipesHolder = SKNode();
        pipesHolder.name = "Holder";
        
        let pipeUp = SKSpriteNode(imageNamed: "Pipe 1");
        let pipeDown = SKSpriteNode(imageNamed: "Pipe 1");
        
        let scoreNode = SKSpriteNode();
        
        scoreNode.color = SKColor.red;
        
        scoreNode.name = "Score";
        scoreNode.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        scoreNode.position = CGPoint(x: 0, y: 0);
        scoreNode.size = CGSize(width: 5, height: 300);
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size);
        scoreNode.physicsBody?.categoryBitMask = ColliderType.Score;
        scoreNode.physicsBody?.collisionBitMask = 0;
        scoreNode.physicsBody?.affectedByGravity = false;
        scoreNode.physicsBody?.isDynamic = false;

        pipeUp.name = "Pipe";
        pipeUp.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        pipeUp.position = CGPoint(x: 0, y: 630);
        pipeUp.yScale = 1.5;
        pipeUp.zRotation = CGFloat(M_PI);
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size);
        pipeUp.physicsBody?.categoryBitMask = ColliderType.Pipes;
        pipeUp.physicsBody?.affectedByGravity = false;
        pipeUp.physicsBody?.isDynamic = false;
        
        pipeDown.name = "Pipe";
        pipeDown.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        pipeDown.position = CGPoint(x: 0, y: -630);
        pipeDown.yScale = 1.5;
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size);
        pipeDown.physicsBody?.categoryBitMask = ColliderType.Pipes;
        pipeDown.physicsBody?.affectedByGravity = false;
        pipeDown.physicsBody?.isDynamic = false;
        
        pipesHolder.zPosition = 5;
        pipesHolder.position.x = self.frame.width + 100;
        pipesHolder.position.y = CGFloat.randomBetweenNumbers(firstNum: -300, secondNum: 300);
        //pipesHolder.position = CGPoint(x: 300, y: 0);
        
        pipesHolder.addChild(pipeUp);
        pipesHolder.addChild(pipeDown);
        pipesHolder.addChild(scoreNode);
        
        self.addChild(pipesHolder);
        
        let destination = self.frame.width * 2;
        let move = SKAction.moveTo(x: -destination, duration: TimeInterval(10));
        let remove = SKAction.removeFromParent();
        
        pipesHolder.run(SKAction.sequence([move, remove]), withKey: "Move");
        
    }
    
    func spawnObstacles() {
        let spawn = SKAction.run({ () -> Void in
            self.createPipes();
        });
        
        let delay = SKAction.wait(forDuration: TimeInterval(2));
        let sequence = SKAction.sequence([spawn, delay]);
        
        self.run(SKAction.repeatForever(sequence), withKey: "Spawn");
        
    }
    
    func createLabel() {
        scoreLabel.zPosition = 6;
        scoreLabel.position = CGPoint(x: 0, y: 450);
        scoreLabel.fontSize = 120;
        scoreLabel.text = "0";
        self.addChild(scoreLabel);
    }
    
    func incrementScore() {
        score += 1;
        scoreLabel.text = String(score);
    }
    
    func birdDied() {
        self.finishRecording()
        
        self.removeAction(forKey: "Spawn");
        
        for child in children {
            if child.name == "Holder" {
                child.removeAction(forKey: "Move");
            }
        }
        
        isAlive = false;
        
        bird.texture = bird.diedTexture;
        
        let highscore = GameManager.instance.getHighScore();
        
        if highscore < score {
            //If Current Score Is Greater Than Current Highscore, Then We Have A New Highscore
            GameManager.instance.setHighScore(highscore: score);
        }
        
        let retry = SKSpriteNode(imageNamed: "Retry");
        let quit = SKSpriteNode(imageNamed: "Quit");
        
        retry.name = "Retry";
        retry.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        retry.position = CGPoint(x: -150, y: -150);
        retry.zPosition = 7;
        retry.setScale(0);
        
        quit.name = "Quit";
        quit.anchorPoint = CGPoint(x: 0.5, y: 0.5);
        quit.position = CGPoint(x: 150, y: -150);
        quit.zPosition = 7;
        quit.setScale(0);
        
        let scaleUp = SKAction.scale(to: 1, duration: TimeInterval(0.5))
        
        retry.run(scaleUp);
        quit.run(scaleUp);
        
        self.addChild(retry);
        self.addChild(quit);
    }
    
    public func startRecording(callback: @escaping (_ peak: Float) ->Void) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { timer in
                self.audioRecorder.updateMeters()
                let peakPower = self.audioRecorder.peakPower(forChannel: 0)
                callback(peakPower)
            }
        } catch {
            finishRecording()
        }
    }
    
    public func finishRecording() {
        timer.invalidate();
        audioRecorder.stop()
        audioRecorder = nil
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
