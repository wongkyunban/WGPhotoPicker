//
//  SinglePhotoPreviewViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/12.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

//图片预览
class SinglePhotoPreviewViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,PhotoPreviewCellDelegate {
    //图片模型数据，接收上一个控制器传过来的数据
    var selectImages:[PhotoImageModel]?
    
    private var collectionView: UICollectionView?
    private let cellIdentifier = "cellIdentifier"
    //接收上一个控制器传过来的数据，预览的第一张图片，默认设置为第一张
    var currentPage: Int = 0
    
    //上一个视图控制器即为此控制器的代理
    weak var sourceDelegate: ViewController?
    
    
    
    //设置导航条的样式
    let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 64))
    let navItem = UINavigationItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        //返回按钮
       // self.navigationController?.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "back", style: .plain, target: self, action: nil)
        
        self.configCollectionView()
        self.configNavigationBar()

    }
    
    //设置导航栏
    private func configNavigationBar(){
        //设置状态栏样式
        UIApplication.shared.statusBarStyle = .lightContent
        
        navigationBar.barStyle = .blackOpaque
        navigationBar.tintColor = UIColor.white
        //导航栏左按钮的样式及对应的点击事件
       navItem.leftBarButtonItem = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(SinglePhotoPreviewViewController.back))
        //导航栏右按钮的样式及对应的点击事件
        navItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(SinglePhotoPreviewViewController.eventRemoveImage))
        navigationBar.pushItem(navItem, animated: true)
        self.view.addSubview(navigationBar)


        
    }
    //返回
    func back(){
        self.dismiss(animated: false, completion: nil)
    }
    //删除图片
    func eventRemoveImage(){
        //在数组中移除图片数据
        let element = self.selectImages?.remove(at: self.currentPage)
        //更新标题
        self.updatePageTitle()
        //调用代理，在上一个视图控制器中将图片数据删除，保证两边操作的一致性   （返回上一个视图时应该要更新一下上一个视图）
        self.sourceDelegate?.removeElement(element: element)
        //如果删除后，还有图片数据就刷新UICollectionView,否则回到上一个页面（将当前页面弹出栈）
        if (self.selectImages?.count)! > 0{
            self.collectionView?.reloadData()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //打开此页面时，先展示上个视图点击的图片
        self.collectionView?.setContentOffset(CGPoint(x: CGFloat(self.currentPage) * self.view.bounds.width, y: 0), animated: false)
        //更新标题
        self.updatePageTitle()
    }
    //更新导航栏的标题
    private func updatePageTitle(){
        navItem.title = String(self.currentPage+1) + "/" + String(self.selectImages!.count)
    }
    
    //设置collectionView
    func configCollectionView(){
        self.automaticallyAdjustsScrollViewInsets = false
        let layout = UICollectionViewFlowLayout()
        //水平滚动
        layout.scrollDirection = .horizontal
        //Cell的大小
        layout.itemSize = CGSize(width:self.view.frame.width,height: self.view.frame.height)
        //水平间隔
        layout.minimumInteritemSpacing = 0
        //垂直间隔
        layout.minimumLineSpacing = 0
        //初始化collectionView
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        //设置数据源代理
        self.collectionView!.dataSource = self
        //设置其他事件代理
        self.collectionView!.delegate = self
        //分页效果
        self.collectionView!.isPagingEnabled = true
        //设置不用滚动到顶部
        self.collectionView!.scrollsToTop = false
        //不显示水平滚动条
        self.collectionView!.showsHorizontalScrollIndicator = false
        //设置偏移
        self.collectionView!.contentOffset = CGPoint(x:0, y: 0)
        //设置contentSize
        self.collectionView!.contentSize = CGSize(width: self.view.bounds.width * CGFloat(self.selectImages!.count), height: self.view.bounds.height)
        //将collectionView加入view中
        self.view.addSubview(self.collectionView!)
        //注册一个复用的cell
        self.collectionView!.register(PhotoPreviewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
    }
    
    // MARK: -  collectionView dataSource delagate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //在section中显示所以图片
        return self.selectImages!.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as! PhotoPreviewCell
        //将当前控制器作为PhotoPreviewCell的代理
        cell.delegate = self
        if let asset = self.selectImages?[indexPath.row] {
            //渲染Cell
            cell.renderModel(asset: asset.data!)
        }
        
        return cell
    }
    
    // MARK: -  Photo Preview Cell Delegate
    var status:Bool = false
    func onImageSingleTap() {
        status = !self.navigationBar.isHidden
        UIView.animate(withDuration: 0.5) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
            self.navigationBar.isHidden = self.status

        }
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    override var prefersStatusBarHidden: Bool {
        return status
    }
    // 图片停止滚动时，更新标题
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        self.currentPage = Int(offset.x / self.view.bounds.width)
        self.updatePageTitle()
    }
    
}
