//
//  ViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/4.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController,PhotoPickerControllerDelegate {
    
    var selectModel = [PhotoImageModel]()
    var containerView = UIView()
    
    var triggerRefresh = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.containerView)
        self.checkNeedAddButton()
        self.renderView()
    }
    //检查需不需要将按钮显示出来  添加的条件是：图片数没有小于设定的最大数并且当前布局中没有出现按钮
    private func checkNeedAddButton(){
        if self.selectModel.count < PhotoPickerController.imageMaxSelectedNum && !hasButton() {
            selectModel.append(PhotoImageModel(type: ModelType.Button, data: nil))
        }
    }
    //判断按钮是否已存在
    private func hasButton() -> Bool{
        for item in self.selectModel {
            if item.type == ModelType.Button {
                return true
            }
        }
        return false
    }
    //删除图片，
    func removeElement(element: PhotoImageModel?){
        if let current = element {
            self.selectModel = self.selectModel.filter({$0 != current});
        }
    
    }
    
    //打开此页面时，更新视图
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barStyle = .default
        self.updateView()
       /* if self.triggerRefresh {
            self.triggerRefresh = false
            self.updateView()
        }*/
        
    }
    
    private func updateView(){
        self.clearAll()
        self.checkNeedAddButton()
        self.renderView()
    }
    //初始化视图
    private func renderView(){
        
        //检查是否有图片，没有的话立即返回
        if selectModel.count <= 0 {return}
        //显示区域宽度
        let totalWidth = UIScreen.main.bounds.width
        //图片间隔
        let space:CGFloat = 10
        //每行显示图片的数量
        let lineImageTotal = 4
        //计算选择好后的图片要用多行来显示  公式：行数 = 图片总数／每一行显示的数量
        let line = self.selectModel.count / lineImageTotal
        //计算不够一行的图片数   0 <= 值 < lineImageTotal
        let lastItems = self.selectModel.count % lineImageTotal
        //计算除去图片之前的间隔之后，所有图片加起来的宽度。
        let lessItemWidth = (totalWidth - (CGFloat(lineImageTotal) + 1) * space)
        //计算每张图片的宽度
        let itemWidth = lessItemWidth / CGFloat(lineImageTotal)
        
        //优先渲染满一行的图片
        for i in 0 ..< line {
            //计算纵坐标
            let itemY = CGFloat(i+1) * space + CGFloat(i) * itemWidth
            for j in 0 ..< lineImageTotal {
                //计算横坐标
                let itemX = CGFloat(j+1) * space + CGFloat(j) * itemWidth
                //计算图片在数组中的下标
                let index = i * lineImageTotal + j
                //渲染图片视图
                self.renderItemView(itemX: itemX, itemY: itemY, itemWidth: itemWidth, index: index)
            }
        }
        
        //渲染最后一行不满一行的图片
        for i in 0..<lastItems{
            //计算横坐标
            let itemX = CGFloat(i+1) * space + CGFloat(i) * itemWidth
            //计算纵坐标
            let itemY = CGFloat(line+1) * space + CGFloat(line) * itemWidth
            //计算图片在数组中的下标
            let index = line * lineImageTotal + i
            //渲染图片视图
            self.renderItemView(itemX: itemX, itemY: itemY, itemWidth: itemWidth, index: index)
        }
        //利用ceil上取整函数，获得一共有多少行图片
        let totalLine = ceil(Double(self.selectModel.count) / Double(lineImageTotal))
        //根据图片行数据计算出containerView容器的高度。
        let containerHeight = CGFloat(totalLine) * itemWidth + (CGFloat(totalLine) + 1) *  space
        //初始化containerView容器的布局
        self.containerView.frame = CGRect(x:0, y:64, width:totalWidth,  height:containerHeight)
    }
    
    //渲染每一张图片视图
    private func renderItemView(itemX:CGFloat,itemY:CGFloat,itemWidth:CGFloat,index:Int){
        //在模型数组拿出对应下标的图片
        let itemModel = self.selectModel[index]
        //初始化一个添加图片的按钮
        let button = UIButton(frame: CGRect(x:itemX, y:itemY, width:itemWidth, height: itemWidth))
        //按钮背景颜色
        button.backgroundColor = UIColor.red

        //按钮的标识，就是图片的下标
        button.tag = index
        
        //根据拿回来的模型数据里的type，判断是按钮不是图片数据，是按钮就将按钮的背景图片设置为image_select，是图片数据的话就设置为对应的图片
        if itemModel.type == ModelType.Button {
            //清除掉按钮的背景
            button.backgroundColor = UIColor.clear
            //给按钮添加一个点击事件，打开添加图片的对话框
            button.addTarget(self, action: #selector(ViewController.eventAddImage), for: .touchUpInside)
            //依比例缩放后填充到视图中，这样一来，图片超出部分会被截去
            button.contentMode = .scaleAspectFill
            //按钮的边厚度为2点
            button.layer.borderWidth = 2
            //按钮边的颜色
            button.layer.borderColor = UIColor.init(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
            //设置按钮的背景图片
            button.setImage(UIImage(named: "image_select"), for: UIControlState.normal)
        } else {
            //给按钮添加一个点击事件，用来预览图片
            button.addTarget(self, action: #selector(ViewController.eventPreview), for: .touchUpInside)
            //拿出模型中的图片数据
            if let asset = itemModel.data {
                //根据当前设备的分辨率计算图片的像素
                let pixSize = UIScreen.main.scale * itemWidth
                //根据模型中的图片数据，和图片的尺寸信息，请求对应的图片，并在回调中设置好按钮的背景。
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: pixSize, height: pixSize), contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image, info) -> Void in
                    if image != nil {
                        button.setImage(image, for: UIControlState.normal)
                        button.contentMode = .scaleAspectFill
                        button.clipsToBounds = true
                    }
                })
            }
        }
        //初始化好按钮信息就将按钮放入containerView容器中
        self.containerView.addSubview(button)
    }
    //清除containerView容器中的所有视图数据，在打开页面时初始化时调用
    private func clearAll(){
        for subview in self.containerView.subviews {
            if let view =  subview as? UIButton {
                view.removeFromSuperview()
            }
        }
    }
    
    //点击图片按钮时触发这个预览图片事件
    func eventPreview(button:UIButton){
        let preview = SinglePhotoPreviewViewController()
        //获取只有图片数据没有那个添加按钮的图片模型数组
        let data = self.getModelExceptButton()
        //将图片模型数组传递给预览视图控制器
        preview.selectImages = data
        //将当前控制器设置为预览视图控制器的代理
        preview.sourceDelegate = self
        //将点击要先预览的图片下标传给预览视图控制器
        preview.currentPage = button.tag
        //打开预览视图
        self.show(preview, sender: nil)
    }
    
    //点击添加图片的按钮事件
    func eventAddImage() {
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // change the style sheet text color
        alert.view.tintColor = UIColor.blue
        
        let actionCancel = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        let actionCamera = UIAlertAction.init(title: "拍照", style: .default) { (UIAlertAction) -> Void in
            DispatchQueue.main.async {
            self.selectByCamera()
            }
        }
        
        let actionPhoto = UIAlertAction.init(title: "从手机照片中选择", style: .default) { (UIAlertAction) -> Void in
            DispatchQueue.main.async {

                self.selectFromPhoto()
            }
        }
        
        alert.addAction(actionCancel)
        alert.addAction(actionCamera)
        alert.addAction(actionPhoto)
        
        self.present(alert, animated: true, completion: nil)
    }
   
    
    
    /**
     拍照获取
     */
    private func selectByCamera(){
        // todo take photo task
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                let cameraVC = CameraViewController()
                cameraVC.callbackPicutureData = { imgData in
                    self.savePic(images: imgData)
                }
                //UIApplication.shared.keyWindow?.currentViewController()?.present(cameraVC, animated: true, completion: nil)
                self.show(cameraVC, sender: nil)
            }else{
                //系统不支持
            }
            
        }

        }
    //拍照保存图片
    func savePic(images: [PHAsset]){
        for item in images {
            //将图片装入图片模型数组最前面
            self.selectModel.insert(PhotoImageModel(type: ModelType.Image, data: item), at: 0)
        }
        
        
        let total = self.selectModel.count
        //判断选择的图片是否已达上限，是的话，将添加按钮从模型中去掉。
        if total > PhotoPickerController.imageMaxSelectedNum {
            for i in 0 ..< total {
                let item = self.selectModel[i]
                if item.type == .Button {
                    self.selectModel.remove(at: i)
                    
                }
            }
        }
        //重新渲染视图
        self.renderView()

    }
    
    /**
     从相册中选择图片
     */
    private func selectFromPhoto(){
        //检查是否有权限访问相册，没有则申请权限
       PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .authorized:
                //打开本地相册
                self.showLocalPhotoGallery()
                break
            default:
                //提示访问相册权限，这个必须info.plist里申请
                self.showNoPermissionDailog()
                break
            }
        }
    }
    
    private func showNoPermissionDailog(){
        let alert = UIAlertController.init(title: nil, message: "没有打开相册的权限", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //打开本地相册
    private func showLocalPhotoGallery(){
        
        //打开相册控制器
        let picker = PhotoPickerController(type: PageType.RecentAlbum)
        //设置当前控制器为相册控制器的代理
        picker.imageSelectDelegate = self
        //设置相册控制器的弹出方式
        picker.modalPresentationStyle = .popover
        
        // max select number
        PhotoPickerController.imageMaxSelectedNum = 40
        
        // already selected image num
        let realModel = self.getModelExceptButton()
        PhotoPickerController.alreadySelectedImageNum = realModel.count
        //显示相册控制器
        self.show(picker, sender: nil)
        
    }
    //PhotoPickerController选择完图片后，回调这个方法，将选择好的图片显示在视图上。
    func onImageSelectFinished(images: [PHAsset]) {
        self.renderSelectImages(images: images)
    }
    //将选择好的图片装入图片模型数组中
    private func renderSelectImages(images: [PHAsset]){
        for item in images {
            //将图片装入图片模型数组最前面
            self.selectModel.insert(PhotoImageModel(type: ModelType.Image, data: item), at: 0)
        }
        
        
        let total = self.selectModel.count
        //判断选择的图片是否已达上限，是的话，将添加按钮从模型中去掉。
        if total > PhotoPickerController.imageMaxSelectedNum {
            for i in 0 ..< total {
                let item = self.selectModel[i]
                if item.type == .Button {
                    self.selectModel.remove(at: i)

                }
            }
        }
        //重新渲染视图
        self.renderView()
    }
    
    //获取已选择好的图片模型数组除按钮外
    private func getModelExceptButton()->[PhotoImageModel]{
        //新建一个临时图片模型数组
        var newModels = [PhotoImageModel]()
        //过滤掉不是图片的数据，其实就是将那个添加图片的按钮过滤掉，哈哈哈>a<
        for i in 0..<self.selectModel.count {
            let item = self.selectModel[i]
            if item.type != .Button {
                newModels.append(item)
            }
        }
        return newModels
    }
    
}

