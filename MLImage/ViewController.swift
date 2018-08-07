//
//  ViewController.swift
//  MLImage
//
//  Created by 刘智民 on 29/11/2017.
//  Copyright © 2017 刘智民. All rights reserved.
//

import UIKit
import ARKit
import SceneKit


class ViewController: UIViewController,ARSCNViewDelegate,ARSessionDelegate {
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    let arSCNView = ARSCNView()
    let arSession = ARSession()
    var sessionconfig = ARWorldTrackingConfiguration()
    let labAnalytics = UITextView()
    let labResult = UILabel()
    let imageTool = MLImageDetect()
    var resultNode = SCNNode()
    var pos = SCNVector3(0,0,0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ARInit()
        setUpFunctionViews()
        let labFocus = UILabel()
        labFocus.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        labFocus.textAlignment = .center
        labFocus.text = "+"
        labFocus.font = UIFont.systemFont(ofSize: 40)
        labFocus.textColor = .white
        labFocus.center = self.view.center
        labFocus.backgroundColor = .clear
        self.view.addSubview(labFocus)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        arSCNView.session.run(sessionconfig)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        arSCNView.session.pause()
    }
    
    func ARInit() {
        arSession.delegate = self
        arSCNView.session = arSession
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.delegate = self
        arSCNView.frame = self.view.frame
        if !self.view.subviews.contains(arSCNView) {
            self.view.addSubview(arSCNView)
        }
        let scene = SCNScene()
        self.arSCNView.scene = scene
        
        sessionconfig.planeDetection = .horizontal
        
        arSCNView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(handleTap(gesture:))))
    }
    
    func setUpFunctionViews() {
        //分析过程窗口
        labAnalytics.backgroundColor = .clear
        labAnalytics.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200)
        labAnalytics.isEditable = false
        labAnalytics.textColor = .white
        arSCNView.addSubview(labAnalytics)
        
        labResult.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        labResult.textAlignment = .center
        labResult.frame = CGRect(x: 0, y: self.view.bounds.size.height - 40, width: self.view.bounds.width, height: 40)
        labResult.font = UIFont.systemFont(ofSize: 36)
        labResult.textColor = .red
        labResult.adjustsFontSizeToFitWidth = true
        arSCNView.addSubview(labResult)
        
        imageTool.analyticsCallBack = {(content) ->() in
            let foreTxt = self.labAnalytics.text
            self.labAnalytics.text = foreTxt?.appending(content!)
        }
        imageTool.resultCallBack = {(result) ->() in
            guard let resultstring = result else {
                return
            }
            self.showText(content: resultstring)
            self.labResult.text = result
        }
    }
    
    @objc
    func handleTap(gesture:UITapGestureRecognizer) {
        labAnalytics.text = ""
        
        //confirm view
        guard arSCNView.session.currentFrame != nil else {return}
        
        let screenCenter : CGPoint = CGPoint(x: arSCNView.bounds.midX, y: arSCNView.bounds.midY)

        let arHitTestResults : [ARHitTestResult] = arSCNView.hitTest(screenCenter, types: [.featurePoint])

        if let closestResult = arHitTestResults.first { //取得坐标系
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            pos = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z )
            labAnalytics.text = "获取特征值成功开始检测"
            showText(content: "...")
            imageTool.detectImage(image: arSCNView.snapshot().cgImage!)
        } else {
            labAnalytics.text = "获取特征值失败请重新点击取图"
        }
        
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        let font = UIFont(name: "Futura", size: 0.15)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.green
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }

    func showText(content:String) {
        self.resultNode = createNewBubbleParentNode(content)
        self.arSCNView.scene.rootNode.addChildNode(self.resultNode)
        resultNode.position = pos;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

