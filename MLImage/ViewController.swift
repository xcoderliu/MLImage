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
            self.showText(content: result!)
            self.resultNode = SCNNode()
            self.labResult.text = result;
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
            pos = SCNVector3Make(transform.columns.3.x - 0.2, transform.columns.3.y - 0.88, transform.columns.3.z - 0.2)
            labAnalytics.text = "获取特征值成功开始检测"
            showText(content: "...")
            imageTool.detectImage(image: arSCNView.snapshot().cgImage!)
        } else {
            labAnalytics.text = "获取特征值失败请重新点击取图"
        }
        
    }
    
    func showText(content:String) {
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        self.resultNode.removeFromParentNode()
        let resultText = SCNText(string: content, extrusionDepth: 0.01)
        resultText.alignmentMode = kCAAlignmentCenter;
        resultText.font = UIFont.systemFont(ofSize:0.05)
        resultText.firstMaterial?.diffuse.contents = UIColor.blue
        resultText.firstMaterial?.specular.contents = UIColor.white
        resultText.firstMaterial?.isDoubleSided = true
        self.resultNode = SCNNode(geometry: resultText)
        self.resultNode.constraints = [billboardConstraint]
        self.arSCNView.scene.rootNode.addChildNode(self.resultNode)
        resultNode.position = pos;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

