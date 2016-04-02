//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by Scott Gardner on 3/24/16.
//  Copyright (c) 2016 Scott Gardner. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import RxSwift

class GameViewController: UIViewController {
  
  enum Constant: String {
    
    case Good = "Good"
    case Bad = "Bad"
    case HUD = "HUD"
    
    case Trail = "Trail"
    case Explode = "Explode"
    
    case GameOver = "GameOver"
    case TapToPlay = "TapToPlay"
    
    case SpawnGood = "SpawnGood"
    case SpawnBad = "SpawnBad"
    case ExplodeGood = "ExplodeGood"
    case ExplodeBad = "ExplodeBad"
    
    var wav: String { return rawValue + ".wav" }
    var diffusePng: String { return rawValue + "_Diffuse.png" }
    
  }
  
  // MARK: - Properties
  
  var scnView: SCNView!
  var scnScene: SCNScene!
  var cameraNode: SCNNode!
  var spawnTime$ = Variable<NSTimeInterval>(0.0)
  var game = GameHelper.sharedInstance
  var splashNodes = [String: SCNNode]()
  let assetsDirectory = "GeometryFighter.scnassets/"
  lazy var texturesDirectory: String = { self.assetsDirectory + "Textures/" }()
  lazy var soundsDirectory: String = { self.assetsDirectory + "Sounds/" }()
  
  let disposeBag = DisposeBag()
  
  // MARK: - View life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupScene()
    setupCamera()
    setupHUD()
    setupSplash()
    setupSounds()
    
    scnView.rx_rendererUpdateAtTime
      .subscribeNext { [unowned self] in
        if self.game.state == .Playing {
          if $0.time > self.spawnTime$.value {
            self.spawnShape()
            self.spawnTime$.value = $0.time + NSTimeInterval(Float.random(min: 0.2, max: 1.5))
          }
          
          self.cleanScene()
        }
        
        self.game.updateHUD()
      }
      .addDisposableTo(disposeBag)
  }
  
  //  override func shouldAutorotate() -> Bool { // Returns true by default
  //    return true
  //  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  // MARK: - Actions
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    switch game.state {
    case .GameOver:
      return
    case .TapToPlay:
      game.reset()
      game.state = .Playing
      showSplash("")
      return
    default:
      break
    }
    
    let touch = touches.first!
    let location = touch.locationInView(scnView)
    let hitResults = scnView.hitTest(location, options: nil)
    
    guard hitResults.count > 0 else { return }
    
    let result = hitResults.first!
    handleTouchFor(result.node)
  }
  
  func handleTouchFor(node: SCNNode) {
    guard let name = node.name, nodeName = Constant(rawValue: name) else { return }
    
    switch nodeName {
    case .Good:
      handleGoodCollision()
    case .Bad:
      handleBadCollision()
    case .HUD, .TapToPlay, .GameOver:
      return
    default:
      break
    }
    
    createExplosion(node.geometry!, position: node.presentationNode.position, rotation: node.presentationNode.rotation)
    node.removeFromParentNode()
  }
  
  func handleGoodCollision() {
    game.score += 1
    game.playSound(scnScene.rootNode, name: Constant.ExplodeGood.rawValue)
  }
  
  func handleBadCollision() {
    game.lives -= 1
    game.playSound(scnScene.rootNode, name: Constant.ExplodeBad.rawValue)
    game.shakeNode(cameraNode)
    
    guard game.lives > 0 else {
      game.saveState()
      showSplash(Constant.GameOver.rawValue)
      game.playSound(scnScene.rootNode, name: Constant.GameOver.rawValue)
      game.state = .GameOver
      
      scnScene.rootNode.runAction(SCNAction.waitForDuration(5.0)) {
        self.showSplash(Constant.TapToPlay.rawValue)
        self.game.state = .TapToPlay
      }
      
      return
    }
  }
  
  // MARK: - Helpers
  
  func setupView() {
    scnView = view as! SCNView
    scnView.showsStatistics = true
    //    scnView.allowsCameraControl = true // true by default
    scnView.autoenablesDefaultLighting = true
    scnView.playing = true // Force endless playing mode, which prevents entering paused state if there are no animations to play out
  }
  
  func setupScene() {
    scnScene = SCNScene()
    scnView.scene = scnScene
    scnScene.background.contents = GeometryFighterStyleKit.imageOfBackgroundDiffuse()
  }
  
  func setupCamera() {
    cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 5, 10)
    scnScene.rootNode.addChildNode(cameraNode)
  }
  
  func setupHUD() {
    game.hudNode.position = SCNVector3(0.0, 10.0, 0.0)
    scnScene.rootNode.addChildNode(game.hudNode)
  }
  
  func setupSplash() {
    splashNodes[Constant.TapToPlay.rawValue] = createSplash(Constant.TapToPlay.rawValue, imageFileName: texturesDirectory + Constant.TapToPlay.diffusePng)
    splashNodes[Constant.GameOver.rawValue] = createSplash(Constant.GameOver.rawValue, imageFileName: texturesDirectory + Constant.GameOver.diffusePng)
    showSplash(Constant.TapToPlay.rawValue)
  }
  
  func setupSounds() {
    game.loadSound(Constant.SpawnGood.rawValue, fileNamed: soundsDirectory + Constant.SpawnGood.wav)
    game.loadSound(Constant.ExplodeGood.rawValue, fileNamed: soundsDirectory + Constant.ExplodeGood.wav)
    game.loadSound(Constant.SpawnBad.rawValue, fileNamed: soundsDirectory + Constant.SpawnBad.wav)
    game.loadSound(Constant.ExplodeBad.rawValue, fileNamed: soundsDirectory + Constant.ExplodeBad.wav)
    game.loadSound(Constant.GameOver.rawValue, fileNamed: soundsDirectory + Constant.GameOver.wav)
  }
  
  func showSplash(splashName: String) {
    for (name, node) in splashNodes {
      node.hidden = name == splashName ? false : true
    }
  }
  
  func spawnShape() {
    var geometry: SCNGeometry
    
    switch ShapeType.random() {
    case .Box:
      geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
    case .Sphere:
      geometry = SCNSphere(radius: 0.5)
    case .Pyramid:
      geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
    case .Torus:
      geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
    case .Capsule:
      geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
    case .Cylinder:
      geometry = SCNCylinder(radius: 0.3, height: 2.5)
    case .Cone:
      geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
    case .Tube:
      geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
    }
    
    var color = UIColor.random()
    
    // Increase chance of getting black color
    if color != UIColor.blackColor() {
      color = UIColor.random()
    }
    
    geometry.materials.first?.diffuse.contents = color
    
    let geometryNode = SCNNode(geometry: geometry)
    geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
    
    let randomX = Float.random(min: -2.0, max: 2.0)
    let randomY = Float.random(min: 10.0, max: 18.0)
    let force = SCNVector3(randomX, randomY, 0.0)
    let position = SCNVector3(0.05, 0.05, 0.05)
    geometryNode.physicsBody?.applyForce(force, atPosition: position, impulse: true)
    
    let trailEmitter = createTrail(color: color, geometry: geometry)
    geometryNode.addParticleSystem(trailEmitter)
    
    switch color {
    case UIColor.blackColor():
      geometryNode.name = Constant.Bad.rawValue
      game.playSound(scnScene.rootNode, name: Constant.SpawnBad.rawValue)
    default:
      geometryNode.name = Constant.Good.rawValue
      game.playSound(scnScene.rootNode, name: Constant.SpawnGood.rawValue)
    }
    
    scnScene.rootNode.addChildNode(geometryNode)
  }
  
  func createTrail(color color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
    let trail = SCNParticleSystem(named: Constant.Trail.rawValue, inDirectory: nil)!
    trail.emitterShape = geometry
    trail.particleColor = color
    return trail
  }
  
  func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
    let explosion = SCNParticleSystem(named: Constant.Explode.rawValue, inDirectory: nil)!
    explosion.emitterShape = geometry
    explosion.birthLocation = .Surface
    let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
    let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
    let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
    scnScene.addParticleSystem(explosion, withTransform: transformMatrix)
  }
  
  func createSplash(name: String, imageFileName: String) -> SCNNode {
    let plane = SCNPlane(width: 5.0, height: 5.0)
    let splashNode = SCNNode(geometry: plane)
    splashNode.name = name
    splashNode.position = SCNVector3(0.0, 5.0, 0.0)
    splashNode.geometry?.materials.first?.diffuse.contents = imageFileName
    scnScene.rootNode.addChildNode(splashNode)
    return splashNode
  }
  
  func cleanScene() {
    scnScene.rootNode.childNodes.forEach {
      guard $0.presentationNode.position.y < -2.0 else { return }
      $0.removeFromParentNode()
    }
  }
  
}
