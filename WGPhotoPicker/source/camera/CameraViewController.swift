//
//  CameraViewController.swift
//  PhotoPicker
//
//  Created by waterway on 2017/7/7.
//  Copyright © 2017年 dailyios. All rights reserved.
//

/// 自定义相机

import UIKit
import AVFoundation
import Photos

@available(iOS 10.0, *)
class CameraViewController: UIViewController {
    
    // 获取硬件设备，一般是前后摄像头、麦克风
    private var device: AVCaptureDevice?
    // 输入设备，使用 device 初始化
    private var input: AVCaptureDeviceInput?
    // 输出照片
    private var imageOutput: AVCapturePhotoOutput?
    // 输入、输出桥梁，并启动设备
    private var session: AVCaptureSession?
    // 图像预览层，实时显示捕获的图像
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 照片预览
    fileprivate var showImageContainerView: UIView?
    fileprivate var showImageView: UIImageView?
    fileprivate var picData: Data?
    fileprivate var picAsset:[PHAsset] =  [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化
        setupCameraDistrict()
        
        // 设置展示按钮
        setupUI()
        
    }
    
    internal var callbackPicutureData: (([PHAsset]) -> Void)?
    
    
    /// 操作按钮
    private func setupUI() {
        // 拍照
        let takeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        takeButton.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 55)
        takeButton.setImage(#imageLiteral(resourceName: "c_takePhoto"), for: .normal)
        takeButton.addTarget(self, action: #selector(takePhotoAction), for: .touchUpInside)
        view.addSubview(takeButton)
        
        // 摄像头转换
        let cameraChangeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        cameraChangeButton.setImage(#imageLiteral(resourceName: "c_changeSide"), for: .normal)
        cameraChangeButton.center = CGPoint(x: UIScreen.main.bounds.width - 50, y: takeButton.center.y)
        cameraChangeButton.addTarget(self, action: #selector(changeCameraPosition), for: .touchUpInside)
        cameraChangeButton.contentMode = .scaleAspectFit
        view.addSubview(cameraChangeButton)
        
        // 闪光灯
        let flashChangeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        flashChangeButton.center = CGPoint(x: cameraChangeButton.center.x, y: 40)
        flashChangeButton.setImage(#imageLiteral(resourceName: "c_flashAuto"), for: .normal)
        flashChangeButton.contentMode = .scaleAspectFit
        view.addSubview(flashChangeButton)
        
        // 返回按钮
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        backButton.center = CGPoint(x: 20, y: 40)
        backButton.setImage(#imageLiteral(resourceName: "c_back"), for: .normal)
        backButton.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        view.addSubview(backButton)
        
        // 预览图片
        showImageContainerView = UIView(frame: view.bounds)
        showImageContainerView?.backgroundColor = UIColor(white: 1, alpha: 0.7)
        view.addSubview(showImageContainerView!)
        
        let margin: CGFloat = 15
        let height = showImageContainerView!.bounds.height - 120 - margin * 2
        showImageView = UIImageView(frame: CGRect(x: margin, y: margin * 2, width: showImageContainerView!.bounds.width - 2 * margin, height: height))
        showImageView?.contentMode = .scaleAspectFit
        showImageContainerView?.addSubview(showImageView!)
        showImageContainerView?.isHidden = true
        
        // 放弃、使用按钮
        let giveupButton = createImageOperatorButton(nil, CGPoint(x: 100, y: showImageContainerView!.bounds.height - 80), #imageLiteral(resourceName: "c_cancle"))
        giveupButton.addTarget(self, action: #selector(giveupImageAction), for: .touchUpInside)
        let ensureButton = createImageOperatorButton(nil, CGPoint(x: showImageContainerView!.bounds.width - 100, y: showImageContainerView!.bounds.height - 80), #imageLiteral(resourceName: "c_use"))
        ensureButton.addTarget(self, action: #selector(useTheImage), for: .touchUpInside)
    }
    
    private func createImageOperatorButton(_ title: String?, _ center: CGPoint, _ img: UIImage?) -> UIButton {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        btn.center = center
        btn.setTitle(title, for: .normal)
        btn.setImage(img, for: .normal)
        btn.contentMode = .scaleAspectFit
        showImageContainerView?.addSubview(btn)
        return btn
    }
    
    /// 初始化相机
    private func setupCameraDistrict() {
        // 监测相机权限
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { success in
            if !success {
                let alertVC = UIAlertController(title: "相机权限未开启", message: "设置->相机", preferredStyle: .actionSheet)
                alertVC.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
                
            }
        }
        
        // 默认后置相机
        device = cameraWithPosistion(.back)
        input = try? AVCaptureDeviceInput(device: device)
        guard input != nil else {
            print("⚠️ 获取相机失败")
            return
        }
        
        imageOutput = AVCapturePhotoOutput()
        
        session = AVCaptureSession()
        session?.beginConfiguration()
        
        // 图像质量
        session?.sessionPreset = AVCaptureSessionPreset1280x720
        
        // 输入输出设备结合
        if session!.canAddInput(input) {
            session!.addInput(input)
        }
        
        if session!.canAddOutput(imageOutput) {
            session!.addOutput(imageOutput)
        }
        
        // 预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        session?.commitConfiguration()
        
        // 开始取景
        session?.startRunning()
    }
    
    
    /// 根据方向获取前后相机
    ///
    /// - Parameter position: 方向
    /// - Returns: 相机
    private func cameraWithPosistion(_ position: AVCaptureDevicePosition) -> AVCaptureDevice {
        return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: position)
    }
    
    
    /// 返回
    @objc private func backAction() {
        dismiss(animated: true, completion: nil)
    }
    
    /// 拍照
    @objc private func takePhotoAction() {
        let connection = imageOutput?.connection(withMediaType: AVMediaTypeVideo)
        guard connection != nil else {
            print("拍照失败")
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        imageOutput?.capturePhoto(with: photoSettings, delegate: self)
        
    }
    
    /// 前后摄像头转换
    @objc private func changeCameraPosition() {
        // 给设摄像头的切换添加翻转动画
        let animation = CATransition()
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = "oglFlip"
        
        // 重新设置输入输出
        let newDevice: AVCaptureDevice!
        let newInput: AVCaptureDeviceInput?
        
        let position = input?.device.position
        if position == .front {
            newDevice = cameraWithPosistion(.back)
            animation.subtype = kCATransitionFromLeft
        } else {
            newDevice = cameraWithPosistion(.front)
            animation.subtype = kCATransitionFromRight
        }
        
        // 生成新的输入
        newInput = try? AVCaptureDeviceInput(device: newDevice)
        if newInput == nil {
            print("生成新的输入失败")
            return
        }
        
        previewLayer?.add(animation, forKey: nil)
        
        session?.beginConfiguration()
        session?.removeInput(input)
        if session!.canAddInput(newInput) {
            session?.addInput(newInput!)
            input = newInput
        } else {
            session?.addInput(input)
        }
        session?.commitConfiguration()
    }
    
    /// 放弃使用图片
    @objc private func giveupImageAction() {
        showImageView?.image = UIImage()
        showImageContainerView?.isHidden = true
    }
    
    /// 使用图片
    @objc private func useTheImage() {
            self.callbackPicutureData?(self.picAsset)
            self.dismiss(animated: true, completion: nil)
        
    }
}

@available(iOS 10.0, *)
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if error != nil {
            print("error = \(String(describing: error?.localizedDescription))")
        } else {
            // 展示图片
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            if imageData == nil {
                return
            }
            
            picData = imageData
            showImageContainerView?.isHidden = false
            let image = UIImage(data: imageData!)
            showImageView?.image = image
            //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
            //存放照片资源的标志符
            var localId:String!
            PHPhotoLibrary.shared().performChanges({
                let result = PHAssetChangeRequest.creationRequestForAsset(from: image!)
                let assetPlaceholder = result.placeholderForCreatedAsset
                //保存标志符
                localId = assetPlaceholder?.localIdentifier
            }) { (isSuccess: Bool, error: Error?) in
                if isSuccess {
                    print("保存成功!")
                    //通过标志符获取对应的资源
                    let assetResult = PHAsset.fetchAssets(
                        withLocalIdentifiers: [localId], options: nil)
              
                    let asset = assetResult[0]
                    self.picAsset.append(asset)
                    let options = PHContentEditingInputRequestOptions()
                    options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData)
                        -> Bool in
                        return true
                    }
                    //获取保存的图片路径
                    asset.requestContentEditingInput(with: options, completionHandler: {
                        (contentEditingInput:PHContentEditingInput?, info: [AnyHashable : Any]) in
                        print("地址：",contentEditingInput!.fullSizeImageURL!)
                    })
                } else{
                    print("保存失败：", error!.localizedDescription)
                }
            }
            
            
            

        }
    }
}
