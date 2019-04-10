//
//  GameScene.swift
//  FlappyBird
//
//  Created by 西島菜穂子 on 2019/03/16.
//  Copyright © 2019 nahoko.nishijima. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode:SKNode!
    var bird: SKSpriteNode!
    var flowerNode: SKNode!
    var SKAudioNode: SKNode!

    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0  //0...00001
    let groundCategory: UInt32 = 1 << 1 //0...00010
    let wallCategory: UInt32 = 1 << 2 //0...00100
    let flowerCategory: UInt32 = 1 << 4            //追加
    let scoreCategory: UInt32 = 1 << 3 //0...01000
    
    //スコア用
    var scoreA = 0
    var scoreB = 0
    var scoreLabelNode: SKLabelNode!
    var flowerLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard
    
    //SKview上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue:0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //花のノード
        flowerNode = SKNode()
        scrollNode.addChild(flowerNode)
        
        //各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupFlower() //追加 アイテム
        setupScoreLabel()
    }
    
    func setupGround(){
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール　→ 元の位置　→ 左にスクロールと無題に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint (
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
        
        //スプライトにアクションを設定する
        sprite.run(repeatScrollGround)
        
        //スプライトに物理演算を設定する
        sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
        
        //衝突のカテゴリー設定
        sprite.physicsBody?.categoryBitMask = groundCategory
        
        //衝突のときに動かないように設定する
        sprite.physicsBody?.isDynamic = false
        
        //スプライトを追加する
        scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分をスクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y:0, duration:20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: -cloudTexture.size().width , y:0, duration:0)
        
        //左にスクロール→元の位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
        
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width + CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        //壁の画像を読み込む //wallNodeとは？
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを生成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける瞬間の長さを鳥のサイズの３倍とする
        let slit_length = birdSize.height * 3
        
        //瞬間位置の上下の振れ幅をとりのサイズの３倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height)/2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードをのせるノードを作成
            let wall = SKNode() //spriteじゃない
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y:0)
            wall.zPosition = -50 //雲より手前、地面より奥
        
            //0からrandom_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足してし下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture) //sprite
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突のときに動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突のときに動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            // ここまでスコア
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの時間まちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        //壁を作成→時間まち→壁の作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        wallNode.run(repeatForeverAnimation)
}
    
    func setupBird() {
        //鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed:"bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed:"bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.1)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定　//ここもいじる！
        bird.physicsBody?.categoryBitMask = birdCategory
        //当てられる側はbird 跳ね返る
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        //衝突検知
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | flowerCategory
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
    //花(アイテム)はここから
    func setupFlower() {
        //花の画像を読み込む
        let flowerTexture = SKTexture(imageNamed: "flower")
        flowerTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + flowerTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveFlower = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを生成
        let removeFlower = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let flowerAnimation = SKAction.sequence([moveFlower,removeFlower])
        
        ////////////////////////////////////////////
        let createFlowerAnimation = SKAction.run({
            //壁関連のノードをのせるノードを作成
            let flower = SKNode() //spriteじゃない
            
            //フラワーノードの表示する位置を指定する //???
            flower.position = CGPoint(x: self.frame.size.width + flowerTexture.size().width * 3 , y: 0)
            flower.zPosition = 100 //一番手前になるようにする
            
        /////////////////////////////////
            //壁の画像を読み込む //wallNodeとは？
            let wallTexture = SKTexture(imageNamed: "wall")
            wallTexture.filteringMode = .linear
            
            //鳥の画像サイズを取得
            let birdSize = SKTexture(imageNamed: "bird_a").size()
            
            //鳥が通り抜ける瞬間の長さを鳥のサイズの３倍とする
            let slit_length = birdSize.height * 3
            
            //瞬間位置の上下の振れ幅をとりのサイズの３倍とする
            let random_y_range = birdSize.height * 3
            
            //下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
            let groundSize = SKTexture(imageNamed: "ground").size()
            let center_y = groundSize.height + (self.frame.size.height - groundSize.height)/2
            let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range
            //0からrandom_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            //Y軸の下限にランダムな値を足してし下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
           //////////////////////////
    
            //スプライトの表示する位置を指定する
            let sprite = SKSpriteNode(texture: flowerTexture)
            sprite.position = CGPoint(x:0 ,y: under_wall_y + slit_length * 2)
            sprite.position = CGPoint(x:0 ,y: self.frame.size.height/2)
            //スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: flowerTexture.size())
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.categoryBitMask = self.flowerCategory //衝突Category
            sprite.physicsBody?.contactTestBitMask = self.birdCategory
            
            //スプライトを追加する
            flower.addChild(sprite)
            sprite.run(flowerAnimation)
            self.flowerNode.addChild(flower)
        })
        
        //次の花作成までの時間まちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        //花を作成→時間まち→花の作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createFlowerAnimation,waitAnimation]))
        flowerNode.run(repeatForeverAnimation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
        //鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        
        //鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    //SKPhysicsContactDelegateのメソッド、衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        //bodyAかbodyBがscorecategoryと一致するならば
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory
        {
            //1を足す
            print("ScoreUp")
            scoreA += 1
            scoreLabelNode.text = "Score:\(scoreA)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if scoreA + scoreB > bestScore {
                bestScore = scoreA + scoreB
                bestScoreLabelNode.text = "BEST Score:\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
            }
            
        //bodyAかbodyBがflowercategoryと一致するならば
        } else if
            contact.bodyA.categoryBitMask == flowerCategory || contact.bodyB.categoryBitMask  == flowerCategory
        {

        //衝突のときに音なる
            let playSound = SKAction.playSoundFileNamed("sound", waitForCompletion: false)
            self.run(playSound)
        
        //自身を取り除くアクションを生成
            //nodeを取得して削除する
            if contact.bodyA.categoryBitMask == flowerCategory
            {
            contact.bodyA.node?.removeFromParent()
            }
            if contact.bodyB.categoryBitMask == flowerCategory
            {
            contact.bodyB.node?.removeFromParent()
            }
                
        //1を足す
            print("ScoreUp")
            scoreB += 1
            flowerLabelNode.text = "Score:\(scoreB)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if scoreA + scoreB > bestScore {
                bestScore = scoreA + scoreB
                bestScoreLabelNode.text = "BEST Score:\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
            }
            
        } else {
            //壁か地面と衝突した
            print("GameOver")
    
            //スクロールを停止させる
            scrollNode.speed = 0
    
            bird.physicsBody?.collisionBitMask = groundCategory
    
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        scoreA = 0
        scoreLabelNode.text = String("Score:\(scoreA)")
        scoreB = 0
        flowerLabelNode.text = String("Score:\(scoreB)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        flowerNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel(){
        scoreA = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(scoreA)"
        self.addChild(scoreLabelNode)
        
        scoreB = 0
        flowerLabelNode = SKLabelNode()
        flowerLabelNode.fontColor = UIColor.black
        flowerLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        flowerLabelNode.zPosition = 100
        flowerLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        flowerLabelNode.text = "Score:\(scoreB)"
        self.addChild(flowerLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 130)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "BEST Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
}
