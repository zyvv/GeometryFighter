//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by gakki's vi~ on 2018/7/3.
//  Copyright © 2018年 zhangyw@yhyvr.com. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    var splashNodes: [String: SCNNode] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
        setupSounds()
        setupSplash()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.jpg"
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 5, 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func setupSounds() {
        game.loadSound("ExplodeGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeGood.wav")
        game.loadSound("SpawnGood",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnGood.wav")
        game.loadSound("ExplodeBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/ExplodeBad.wav")
        game.loadSound("SpawnBad",
                       fileNamed: "GeometryFighter.scnassets/Sounds/SpawnBad.wav")
        game.loadSound("GameOver",
                       fileNamed: "GeometryFighter.scnassets/Sounds/GameOver.wav")
    }
    
    func spawnShape() {
        var geometry: SCNGeometry
        let color = UIColor.random()
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: 0.5)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .cone:
            geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        }
        geometry.materials.first?.diffuse.contents = color
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3Make(randomX, randomY, 0)
        let position = SCNVector3Make(0.05, 0.05, 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        let tailEmitter = createTrail(color:color, geometry: geometry)
        geometryNode.addParticleSystem(tailEmitter)
        
        scnScene.rootNode.addChildNode(geometryNode)
        if color == UIColor.black {
            geometryNode.name = "BAD"
            game.playSound(scnScene.rootNode, name: "SpawnBad")
        } else {
            geometryNode.name = "GOOD"
            game.playSound(scnScene.rootNode, name: "SpawnGood")
        }
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            
            //因为物理效果模拟此时正在进行中,所以我们不能简单取物体的position来表示它的真实位置,此时的position反应的是动画开始前的位置.SceneKit在动画期间保存了对象的副本,并用副本来执行动画.要想得到动画进行过程中的实际位置,需要使用presentationNode属性.
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let tail = SCNParticleSystem(named: "Tail.scnp", inDirectory: nil)!
        tail.particleColor = color
        tail.emitterShape = geometry
        return tail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3Make(0.0, 10.0, 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func createSplash(name: String, imageFileName: String) -> SCNNode {
        let plane = SCNPlane(width: 5, height: 5)
        let splashNode = SCNNode(geometry: plane)
        splashNode.position = SCNVector3Make(0, 5, 0)
        splashNode.name = name
        splashNode.geometry?.materials.first?.diffuse.contents = imageFileName
        scnScene.rootNode.addChildNode(splashNode)
        return splashNode
    }
    
    func showSplash(splashName: String) {
        for (name, node) in splashNodes {
            if name == splashName {
                node.isHidden = false
            } else {
                node.isHidden = true
            }
        }
    }
    
    func setupSplash() {
        splashNodes["TapToPlay"] = createSplash(name: "TAPTOPLAY",
                                                imageFileName: "GeometryFighter.scnassets/Textures/TapToPlay_Diffuse.png")
        splashNodes["GameOver"] = createSplash(name: "GAMEOVER",
                                               imageFileName: "GeometryFighter.scnassets/Textures/GameOver_Diffuse.png")
        showSplash(splashName: "TapToPlay")
    }
    
    func handleGoodCollision() {
        game.score += 1
        game.playSound(scnScene.rootNode, name: "ExplodeGood")
    }
    
    func handleBadCollision() {
        game.lives -= 1
        game.playSound(scnScene.rootNode, name: "ExplodeBad")
        game.shakeNode(cameraNode)
        
        if game.lives <= 0 {
            game.saveState()
            showSplash(splashName: "GameOver")
            game.playSound(scnScene.rootNode, name: "GameOver")
            game.state = .GameOver
            scnScene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(5) { (node:SCNNode!) -> Void in
                self.showSplash(splashName: "TapToPlay")
                self.game.state = .TapToPlay
            })
        }
    }
    
//    func handleTouchFor(node: SCNNode) {
//        if node.name == "GOOD" {
//            createExplosion(geometry: node.geometry!, position: node.presentation.position, roation: node.presentation.rotation)
//            game.score += 1
//            node.removeFromParentNode()
//        } else if node.name == "BAD" {
//            game.lives -= 1
//            createExplosion(geometry: node.geometry!, position: node.presentation.position, roation: node.presentation.rotation)
//            node.removeFromParentNode()
//        }
//    }
//
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if game.state == .GameOver {
            return
        }
        if game.state == .TapToPlay {
            game.reset()
            game.state = .Playing
            showSplash(splashName: "")
            return
        }
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if let result = hitResults.first {
            
            if result.node.name == "HUD" || result.node.name == "GAMEOVER" || result.node.name == "TAPTOPLAY" {
                return
            } else if result.node.name == "GOOD" {
                handleGoodCollision()
            } else if result.node.name == "BAD" {
                handleBadCollision()
            }
            
            createExplosion(geometry: result.node.geometry!, position: result.node.presentation.position, roation: result.node.presentation.rotation)
            result.node.removeFromParentNode()
            
//            handleTouchFor(node: result.node)
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position:SCNVector3, roation:SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(roation.w, roation.x, roation.y, roation.z)
        let translationMatrix =
            SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if game.state == .Playing {
            cleanScene()
            game.updateHUD()
            if time > spawnTime {
                spawnShape()
                spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
            }
        }
        
    }
}


