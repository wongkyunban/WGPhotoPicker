//
//  PhotoPreviewViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/8.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

//用于在选择图片，点中图片对图片进行预览
class PhotoPreviewViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,PhotoPreviewBottomBarViewDelegate,PhotoPreviewToolbarViewDelegate,PhotoPreviewCellDelegate {
    //接受从PhotoCollectionViewController传过来的所有图片数据，作为其数据源
    var allSelectImage: PHFetchResult<AnyObject>?
    //定义一个collectionView
    var collectionView: UICollectionView?
    //接受从PhotoCollectionViewController传过来的点击的图片的下标
    var currentPage: Int = 1
    //声明复用的Cell ID
    let cellIdentifier = "PhotoPreviewCell"
    //接受PhotoCollectionViewController作为当前控制器的代理
    weak var fromDelegate: PhotoCollectionViewControllerDelegate?
    //顶部的工具栏
    private var toolbar: PhotoPreviewToolbarView?
    //底部的工具栏
    private var bottomBar: PhotoPreviewBottomBarView?
    
    private var isAnimation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configCollectionView()
        self.configToolbar()
    }
    //设置工具栏
    private func configToolbar(){
        //初始化顶部工具栏
        self.toolbar = PhotoPreviewToolbarView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
        //设置代理
        self.toolbar?.delegate = self
        //设置数据源代理
        self.toolbar?.sourceDelegate = self
        //将顶部工具栏加入当前视图
        self.view.addSubview(toolbar!)

        let positionY = self.view.bounds.height - 50
        //初始化底部工具栏
        self.bottomBar = PhotoPreviewBottomBarView(frame: CGRect(x: 0,y: positionY,width: self.view.bounds.width,height: 50))
        //设置代理
        self.bottomBar?.delegate = self
        //设置底部显示选择图片数的视图
        self.bottomBar?.changeNumber(number: PhotoImage.instance.selectedImage.count, animation: false)
        //将底部工具栏加入当前视图
        self.view.addSubview(bottomBar!)
    }
    
    // 点击PhotoPreviewBottomBarView中的完成按钮就会回调这个方法
    func onDoneButtonClicked() {
        if let nav = self.navigationController as? PhotoPickerController {
            nav.imageSelectFinish()
        }
    }
    
    //点击PhotoPreviewToolbarView中的反回按钮就会回调这个方法
    func onToolbarBackArrowClicked() {
        //将当前控制器弹出栈
        _ = self.navigationController?.popViewController(animated: true)
        
        if let delegate = self.fromDelegate {
            //调用代理PhotoCollectionViewController的onPreviewPageBack方法
            delegate.onPreviewPageBack()
        }
    }
    //点击PhotoPreviewToolbarView中的checkbox按钮就会回调这个方法
    func onSelected(select: Bool) {
        let currentModel = self.allSelectImage![self.currentPage]
        if select {
            //将选中的图片数据放入缓存中。
            PhotoImage.instance.selectedImage.append(currentModel as! PHAsset)
        } else {
            //没有选中的话，就将图片从缓存删除
            if let index = PhotoImage.instance.selectedImage.index(of: currentModel as! PHAsset){
                PhotoImage.instance.selectedImage.remove(at: index)
            }
        }
        //显示数字
        self.bottomBar?.changeNumber(number: PhotoImage.instance.selectedImage.count, animation: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // fullscreen controller
        self.navigationController?.isNavigationBarHidden = true
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        self.collectionView?.setContentOffset(CGPoint(x: CGFloat(self.currentPage) * self.view.bounds.width, y: 0), animated: false)
        
        self.changeCurrentToolbar()
    }
    //配置collectionview
    func configCollectionView(){
        self.automaticallyAdjustsScrollViewInsets = false
        //定义流布局
        let layout = UICollectionViewFlowLayout()
        //水平滚动
        layout.scrollDirection = .horizontal
        //每个cell所在的布局大小
        layout.itemSize = CGSize(width: self.view.frame.width,height: self.view.frame.height)
        //水平间隔
        layout.minimumInteritemSpacing = 0
        //垂直间隔
        layout.minimumLineSpacing = 0
        
        //初始化collectionView
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        //设置collectionView的背景
        self.collectionView!.backgroundColor = UIColor.black
        //设置数据源
        self.collectionView!.dataSource = self
        //设置代理
        self.collectionView!.delegate = self
        //分页显示
        self.collectionView!.isPagingEnabled = true
        //不用滚到最顶，其实这个设不设都没有什么关系
        self.collectionView!.scrollsToTop = false
        //不显示水平滑动指示块
        self.collectionView!.showsHorizontalScrollIndicator = false
        //设置collectionView的外边距
        self.collectionView!.contentOffset = CGPoint.zero
        //设置内容大小
        self.collectionView!.contentSize = CGSize(width: self.view.bounds.width * CGFloat(self.allSelectImage!.count), height: self.view.bounds.height)
        //将布局添加上视图
        self.view.addSubview(self.collectionView!)
        //注册复用的cell
        self.collectionView!.register(PhotoPreviewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
    }
    
    // MARK: -  collectionView dataSource delagate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allSelectImage!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath as IndexPath) as! PhotoPreviewCell
        //将当前控制器作为Cell的代理
        cell.delegate = self
        if let asset = self.allSelectImage![indexPath.row] as? PHAsset {
            //渲染Cell视图
            cell.renderModel(asset: asset)
        }
        
        return cell
    }
    
    // MARK: -  Photo Preview Cell Delegate
    func onImageSingleTap() {
        //判断是否已经出现过动画了，是则返回
        if self.isAnimation {
            return
        }
        
        self.isAnimation = true
        //隐藏顶部或底部的工具栏
        if self.toolbar!.frame.origin.y < 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: [UIViewAnimationOptions.curveEaseOut], animations: { () -> Void in
                self.toolbar!.frame.origin = CGPoint.zero
                var originPoint = self.bottomBar!.frame.origin
                originPoint.y = originPoint.y - self.bottomBar!.frame.height
                self.bottomBar!.frame.origin = originPoint
                }, completion: { (isFinished) -> Void in
                    if isFinished {
                        self.isAnimation = false
                    }
            })
        } else {
            //显示顶部或底部的工具栏
            UIView.animate(withDuration: 0.3, delay: 0, options: [UIViewAnimationOptions.curveEaseOut], animations: { () -> Void in
                self.toolbar!.frame.origin = CGPoint(x:0, y: -self.toolbar!.frame.height)
                var originPoint = self.bottomBar!.frame.origin
                originPoint.y = originPoint.y + self.bottomBar!.frame.height
                self.bottomBar!.frame.origin = originPoint
                
                }, completion: { (isFinished) -> Void in
                    if isFinished {
                        self.isAnimation = false
                    }
            })
        }
        
    }
    
    
    // MARK: -  scroll page
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        //滑动图片时，计算时第几张图片
        self.currentPage = Int(offset.x / self.view.bounds.width)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //当滚动图片停止后，检查它是否需要设置右上角的选中按钮是否要设置为已选中
        self.changeCurrentToolbar()
    }
    //改变当前图片对应上面的checkbox是否应该选中。
    private func changeCurrentToolbar(){
        //检查缓存中是否有此图片数据，有，则设选择，无，则不执行任何操作。
        let model = self.allSelectImage![self.currentPage] as! PHAsset
        if let _ = PhotoImage.instance.selectedImage.index(of: model){
            self.toolbar!.setSelect(select: true)
        } else {
            self.toolbar!.setSelect(select: false)
        }
    }
    
}
