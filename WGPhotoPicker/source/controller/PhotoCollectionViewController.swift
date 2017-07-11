 //
//  PhotoCollectionViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/6.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "photoCollectionViewCell"

protocol PhotoCollectionViewControllerDelegate:class {
    func onPreviewPageBack()
}

class PhotoCollectionViewController: UICollectionViewController, PHPhotoLibraryChangeObserver,PhotoCollectionViewCellDelegate,PhotoCollectionViewControllerDelegate,AlbumToolbarViewDelegate {
	
    let imageManager = PHCachingImageManager()
    //工具栏的高度
	private let toolbarHeight: CGFloat = 44.0
	
	var assetGridThumbnailSize: CGSize?
    //用于接收上个视图控制器发过来的图片集
	var fetchResult: PHFetchResult<PHObject>?
	var previousPreheatRect: CGRect?
    //底部的工具栏
    var toolbar: AlbumToolbarView?
    
	override func viewDidLoad() {
		super.viewDidLoad()
        //初始化collectionView的布局
        let originFrame = self.collectionView!.frame
        self.collectionView!.frame = CGRect(x:originFrame.origin.x, y:originFrame.origin.y, width:originFrame.size.width, height: originFrame.height - self.toolbarHeight)
        
		self.resetCacheAssets()
        
        //注册观察者
		PHPhotoLibrary.shared().register(self)
		//设置collectionView视图四周的外边距
		self.collectionView?.contentInset = UIEdgeInsetsMake(
            PhotoPickerConfig.MinimumInteritemSpacing,
            PhotoPickerConfig.MinimumInteritemSpacing,
            PhotoPickerConfig.MinimumInteritemSpacing,
            PhotoPickerConfig.MinimumInteritemSpacing
        )
		//注册复用的cell
		self.collectionView!.register(UINib.init(nibName: reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		
		self.configBackground()
        self.configBottomToolBar()
        self.configNavigationBar()
	}
    
    //设置底部的工具栏
	private func configBottomToolBar() {
        if self.toolbar != nil {return}
		let width = UIScreen.main.bounds.width
        let positionX = UIScreen.main.bounds.height - self.toolbarHeight
        //设置底部的工具栏的布局
        self.toolbar = AlbumToolbarView(frame: CGRect(x:0,y: positionX,width: width,height: self.toolbarHeight))
        //将当前控制器类设置为底部的工具栏的代理
        self.toolbar?.delegate = self
        //将底部工具栏添加上视图
		self.view.addSubview(self.toolbar!)
        //如果在初始化时，公共存图片（缓存）有图片就设置底部工具栏上的数字显示
        if PhotoImage.instance.selectedImage.count > 0 {
            self.toolbar?.changeNumber(number: PhotoImage.instance.selectedImage.count)
        }
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        //显示导航栏
		self.navigationController?.isNavigationBarHidden = false
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        
        if assetGridThumbnailSize == nil {
            let scale = UIScreen.main.scale
            let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = cellSize.width * scale
            assetGridThumbnailSize = CGSize(width: size, height: size)
        }
	}
    
    // 点击底部工具栏上的完成按钮就会回调这个方法
    func onFinishedButtonClicked() {
        if let nav = self.navigationController as? PhotoPickerController {
            //调用 PhotoPickerController的imageSelectFinish完成图片选择
            nav.imageSelectFinish()
        }
    }
    
    //设置导航栏
    private func configNavigationBar(){
        // 导航栏上的取消按钮点击事件绑定
        let cancelButton = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: self, action: #selector(PhotoCollectionViewController.eventCancel))
        self.navigationItem.rightBarButtonItem = cancelButton
    }
    
    // 导航栏上的取消按钮
    func eventCancel(){
        //清空图片数据缓存
        PhotoImage.instance.selectedImage.removeAll()
        //关闭当前视图控制器
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.updateCacheAssets()
	}
	
	// MARK: -   image caches
	private func resetCacheAssets() {
        //清空所有图片缓存
		self.imageManager.stopCachingImagesForAllAssets()
		self.previousPreheatRect = CGRect.zero
        
	}
	
	func updateCacheAssets() {
		let isViewVisible = self.isViewLoaded && self.view.window != nil;
		if !isViewVisible { return; }
		
		// The preheat window is twice the height of the visible rect.
		var preheatRect = self.collectionView?.bounds
		if preheatRect != nil {
			preheatRect = preheatRect!.insetBy(dx: 0, dy: -0.5 * preheatRect!.height) ;
			
			let delta = abs(preheatRect!.midY - self.previousPreheatRect!.midY)
			
			if (delta > self.collectionView!.bounds.height / 3.0) {
				
				var addedIndexPaths = [IndexPath]()
				var removedIndexPaths = [IndexPath]()
				self.computeDifferenceBetweenRect(oldRect: self.previousPreheatRect!, newRect: preheatRect!, removedHandler: { (removedRect) -> Void in
						// somde code
						let indexPaths = self.collectionView!.aapl_indexPathsForElementsInRect(rect: removedRect)
						if indexPaths != nil {
                            removedIndexPaths.append(contentsOf: indexPaths!)
						}
					}, addedHandler: { (addedRect) -> Void in
						
						let indexPaths = self.collectionView!.aapl_indexPathsForElementsInRect(rect: addedRect)
						if indexPaths != nil {
                            addedIndexPaths.append(contentsOf: indexPaths!)
						}
					})
				
				let assetsToStartCaching = self.assetsAtIndexPaths(indexPaths: addedIndexPaths as [NSIndexPath])
				let assetsToStopCaching = self.assetsAtIndexPaths(indexPaths: removedIndexPaths as [NSIndexPath])
				
				if assetsToStartCaching != nil {
					self.imageManager.startCachingImages(for: assetsToStartCaching!, targetSize: self.assetGridThumbnailSize!, contentMode: .aspectFill, options: nil)
				}
				
				if assetsToStopCaching != nil {
					self.imageManager.stopCachingImages(for: assetsToStopCaching!, targetSize: self.assetGridThumbnailSize!, contentMode: .aspectFill, options: nil)
				}
				
				self.previousPreheatRect = preheatRect;
			}
		}
	}
    
    // MARK: -  PhotoCollectionViewCellDelegate
    func eventSelectNumberChange(number: Int) {
        if let toolbar = self.toolbar {
            toolbar.changeNumber(number: number)
        }
    }
    
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.updateCacheAssets()
	}
	
	func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset]? {
		if indexPaths.count == 0 { return nil; }
		var assets = [PHAsset]()
		for indexPath in indexPaths {
			if let asset = self.fetchResult![indexPath.item] as? PHAsset {
				assets.append(asset)
			}
		}
		return assets;
	}
	
	func computeDifferenceBetweenRect(oldRect: CGRect, newRect: CGRect, removedHandler: (CGRect) -> Void, addedHandler: (CGRect) -> Void) {
		
		if newRect.intersects(oldRect) {
			let oldMaxY = oldRect.maxY
			let oldMinY = oldRect.maxX
			let newMaxY = newRect.maxY ;
			let newMinY = newRect.minY ;
			
			if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x:newRect.origin.x, y:oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
				addedHandler(rectToAdd)
			}
			
			if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
				addedHandler(rectToAdd)
			}
			
			if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
				removedHandler(rectToRemove)
			}
			
			if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
				removedHandler(rectToRemove)
			}
		} else {
			addedHandler(newRect) ;
			removedHandler(oldRect) ;
		}
	}
	
	deinit {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
	}
	
	func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        
        if let collectionChanges = changeInstance.changeDetails(for: fetchResult!) {
			
            DispatchQueue.main.async {
                self.fetchResult = collectionChanges.fetchResultAfterChanges
                let collectionView = self.collectionView!;
                
                if !(collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves) {
                    collectionView.reloadData()
                } else {
                    collectionView.performBatchUpdates({ () -> Void in
                        if let removed = collectionChanges.removedIndexes , removed.count > 0 {
                            collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:0) })
                        }
                        if let inserted = collectionChanges.insertedIndexes , inserted.count > 0 {
                            collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:0) })
                        }
                        if let changed = collectionChanges.changedIndexes , changed.count > 0 {
                            collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:0) })
                        }
                        collectionChanges.enumerateMoves { fromIndex, toIndex in
                            collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                    to: IndexPath(item: toIndex, section: 0))
                        }
                        }, completion: nil)
                }
                
                self.resetCacheAssets()
            }
		}
	}
	
    //设置collectionView背景颜色
	private func configBackground() {
		self.collectionView?.backgroundColor = UIColor.white
	}
	
	override init(collectionViewLayout layout: UICollectionViewLayout) {
		super.init(collectionViewLayout: layout)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
    //设置UICollectionViewCell
	class func configCustomCollectionLayout() -> UICollectionViewFlowLayout {
		let collectionLayout = UICollectionViewFlowLayout()
		
		let width = UIScreen.main.bounds.width - PhotoPickerConfig.MinimumInteritemSpacing * 2
		collectionLayout.minimumInteritemSpacing = PhotoPickerConfig.MinimumInteritemSpacing
		
		let cellToUsableWidth = width - (PhotoPickerConfig.ColNumber - 1) * PhotoPickerConfig.MinimumInteritemSpacing
		let size = cellToUsableWidth / PhotoPickerConfig.ColNumber
        collectionLayout.itemSize = CGSize(width:size, height: size)
		collectionLayout.minimumLineSpacing = PhotoPickerConfig.MinimumInteritemSpacing
		return collectionLayout
	}
	
	// MARK: -  UICollectionView delegate
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.fetchResult != nil ? self.fetchResult!.count : 0
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! photoCollectionViewCell
		
		cell.delegate = self;
        cell.eventDelegate = self
		
		if let asset = self.fetchResult![indexPath.row] as? PHAsset {
			cell.model = asset
			cell.representedAssetIdentifier = asset.localIdentifier
			self.imageManager.requestImage(for: asset, targetSize: self.assetGridThumbnailSize!, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
				if cell.representedAssetIdentifier == asset.localIdentifier {
					cell.thumbnail.image = image
				}
			}
            cell.updateSelected(select: PhotoImage.instance.selectedImage.index(of: asset) != nil)
		}
		return cell
	}
	
	// MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //图片点击时，执行此回调
        //创建预览视图控制器
        let previewController = PhotoPreviewViewController(nibName: nil, bundle: nil)
        //将当前所有图片都传过去给预览视图控制器
        previewController.allSelectImage = self.fetchResult as! PHFetchResult<AnyObject>?
        //传递当前点击中的图片的下标给预览视图控制器
        previewController.currentPage = indexPath.row
        //将当前视图控制器作为其代理
        previewController.fromDelegate = self
        //导航去预览视图控制器
        self.navigationController?.show(previewController, sender: nil)
    }
    //PhotoPreviewViewController中点击返回按钮后，回调此方法
    func onPreviewPageBack() {
        //刷新CollectionView布局
        self.collectionView?.reloadData()
        //设置已选择好的数据量，显示在完成按钮隔离
        self.eventSelectNumberChange(number: PhotoImage.instance.selectedImage.count)
    }
}
