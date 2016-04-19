//
//  ViewController.swift
//  Survival
//
//  Created by Brody Eller on 4/17/16.
//  Copyright © 2016 Brody Eller. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var gameOverLabel: UILabel!
    
    var gameScene: SCNScene!
    
    var spotNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var alienNode: SCNNode!
    var lightFollowNode: SCNNode!
    var scientistNode: SCNNode!
    
    var jumpLeftAction: SCNAction!
    var jumpRightAction: SCNAction!
    var jumpForwardAction: SCNAction!
    var jumpBackwardAction: SCNAction!
    
    var collisionNode: SCNNode!
    var frontCollisionNode: SCNNode!
    var backCollisionNode: SCNNode!
    var leftCollisionNode: SCNNode!
    var rightCollisionNode: SCNNode!
    
    let DegreesToRadians = CGFloat(M_PI) / 180
    let RadiansToDegrees = 180 / CGFloat(M_PI)
    
    let BitmaskAlien = 1
    let BitmaskWall = 2
    let BitmaskEnemy = 4
    let BitmaskFront = 8
    let BitmaskBack = 16
    let BitmaskLeft = 32
    let BitmaskRight = 64
    var activeCollisionBitmask: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupScene()
        setupView()
        setupNodes()
        setupGestures()
        setupActions()
    }
    
    func setupScene() {
        gameScene = SCNScene(named: "Survival.scnassets/GameScene.scn")
        gameScene.physicsWorld.contactDelegate = self
    }
    
    func setupView() {
        sceneView.scene = gameScene
        sceneView.delegate = self
    }
    
    func setupNodes() {
        alienNode = gameScene.rootNode.childNodeWithName("alien", recursively: true)!
        spotNode = gameScene.rootNode.childNodeWithName("spot", recursively: true)!
        spotNode.constraints = [SCNLookAtConstraint (target: alienNode)]
        cameraNode = gameScene.rootNode.childNodeWithName("camera", recursively: true)!
            cameraNode.constraints = [SCNLookAtConstraint (target: alienNode)]
        cameraFollowNode = gameScene.rootNode.childNodeWithName("CameraFollow", recursively: true)!
        lightFollowNode = gameScene.rootNode.childNodeWithName("LightFollow", recursively: true)!
        scientistNode = gameScene.rootNode.childNodeWithName("scientist", recursively: true)!
        
        collisionNode = gameScene.rootNode.childNodeWithName("Collision", recursively: true)!
        frontCollisionNode = gameScene.rootNode.childNodeWithName("Front", recursively: true)!
        backCollisionNode = gameScene.rootNode.childNodeWithName("Back", recursively: true)!
        leftCollisionNode = gameScene.rootNode.childNodeWithName("Left", recursively: true)!
        rightCollisionNode = gameScene.rootNode.childNodeWithName("Right", recursively: true)!
        
        alienNode.physicsBody?.contactTestBitMask = BitmaskEnemy
        
        frontCollisionNode.physicsBody?.contactTestBitMask = BitmaskWall
        backCollisionNode.physicsBody?.contactTestBitMask = BitmaskWall
        leftCollisionNode.physicsBody?.contactTestBitMask = BitmaskWall
        rightCollisionNode.physicsBody?.contactTestBitMask = BitmaskWall
    }
    
    func setupGestures() {
        let swipeRight:UISwipeGestureRecognizer =
            UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeRight.direction = .Right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeLeft.direction = .Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeForward:UISwipeGestureRecognizer =
            UISwipeGestureRecognizer(target: self, action:
                #selector(ViewController.handleGesture(_:)))
        swipeForward.direction = .Up
        self.view.addGestureRecognizer(swipeForward)
        
        let swipeBackward:UISwipeGestureRecognizer =
            UISwipeGestureRecognizer(target: self, action:
                #selector(ViewController.handleGesture(_:)))
        swipeBackward.direction = .Down
        self.view.addGestureRecognizer(swipeBackward)
    }
    
    func setupActions() {
        // 1
        let duration = 0.2
        // 2
        let bounceUpAction = SCNAction.moveByX(0, y: 0.2, z: 0, duration:
            duration * 0.5)
        let bounceDownAction = SCNAction.moveByX(0, y: -0.2, z: 0, duration:
            duration * 0.5)
        // 3
        bounceUpAction.timingMode = .EaseOut
        bounceDownAction.timingMode = .EaseIn
        // 4
        let bounceAction = SCNAction.sequence([bounceUpAction, bounceDownAction])
        // 5
        let moveLeftAction = SCNAction.moveByX(-0.5, y: 0, z: 0, duration:
            duration)
        let moveRightAction = SCNAction.moveByX(0.5, y: 0, z: 0, duration:
            duration)
        let moveForwardAction = SCNAction.moveByX(0, y: 0, z: -0.5, duration:
            duration)
        let moveBackwardAction = SCNAction.moveByX(0, y: 0, z: 0.5, duration:
            duration)
        // 6
        let turnLeftAction = SCNAction.rotateToX(0, y: 90 * DegreesToRadians, z: 0, duration: duration, shortestUnitArc: true)
        let turnRightAction = SCNAction.rotateToX(0, y: -90 * DegreesToRadians, z: 0, duration: duration, shortestUnitArc: true)
        let turnForwardAction = SCNAction.rotateToX(0, y: 0 * DegreesToRadians, z: 0, duration: duration, shortestUnitArc: true)
        let turnBackwardAction = SCNAction.rotateToX(0, y: 180 * DegreesToRadians, z: 0, duration: duration, shortestUnitArc: true)
        // 7
        jumpLeftAction = SCNAction.group([turnLeftAction, bounceAction,
            moveLeftAction])
        jumpRightAction = SCNAction.group([turnRightAction, bounceAction,
            moveRightAction])
        jumpForwardAction = SCNAction.group([turnForwardAction, bounceAction,
            moveForwardAction])
        jumpBackwardAction = SCNAction.group([turnBackwardAction, bounceAction,
            moveBackwardAction])
    }
    
    func handleGesture(sender: UISwipeGestureRecognizer) {
        // 1
        let activeFrontCollision = activeCollisionBitmask & BitmaskFront == BitmaskFront
        let activeBackCollision = activeCollisionBitmask & BitmaskBack == BitmaskBack
        let activeLeftCollision = activeCollisionBitmask & BitmaskLeft == BitmaskLeft
        let activeRightCollision = activeCollisionBitmask & BitmaskRight == BitmaskRight
        // 2
        guard (sender.direction == .Down && !activeFrontCollision) ||
            (sender.direction == .Up && !activeBackCollision) ||
            (sender.direction == .Left && !activeLeftCollision) ||
            (sender.direction == .Right && !activeRightCollision) else {
                return
        }
        
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.Up:
            alienNode.runAction(jumpForwardAction)
        case UISwipeGestureRecognizerDirection.Down:
            alienNode.runAction(jumpBackwardAction)
        case UISwipeGestureRecognizerDirection.Left:
            alienNode.runAction(jumpLeftAction)
        case UISwipeGestureRecognizerDirection.Right:
            alienNode.runAction(jumpRightAction)
            default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


}

extension ViewController: SCNSceneRendererDelegate {
    func renderer(renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: NSTimeInterval) {
        cameraFollowNode.position = alienNode.position
        lightFollowNode.position = alienNode.position
        collisionNode.position = alienNode.position
        let distance = sqrt(((scientistNode.position.x - alienNode.position.x) * (scientistNode.position.x - alienNode.position.x)) + ((scientistNode.position.z - alienNode.position.z) * (scientistNode.position.z - alienNode.position.z)))
        
        if distance <= 0.5 {
            //Game Loss
            print("loss")
        }
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        // 4
        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitmaskWall {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        activeCollisionBitmask |= collisionBoxNode.physicsBody!.categoryBitMask
    }
    // 6
    func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitmaskWall {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        // 9
        activeCollisionBitmask &= ~collisionBoxNode.physicsBody!.categoryBitMask
    }
}