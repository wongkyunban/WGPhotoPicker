//
//  PhotoPickerController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/5.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

enum PageType{
    case List
    case RecentAlbum
    case AllAlbum
}

protocol PhotoPickerControllerDelegate: class{
    func onImageSelectFinished(images: [PHAsset])
}

class PhotoPickerController: UINavigationController {
    
    // 允许选择的最大图片数据，由上一个控制器传递过黎
    static var imageMaxSelectedNum = 4
    
    // 已经选择了的最大图片数据，由上一个控制器传递过黎
    static var alreadySelectedImageNum = 0
    
    //接收上一个视图控制器作为当前控制器的代理
    weak var imageSelectDelegate: PhotoPickerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(type:PageType){
        let rootViewController = PhotoAlbumsTableViewController(style:.plain)
        // clear cache
        PhotoImage.instance.selectedImage.removeAll()
        //rootViewController作为根视图
        super.init(rootViewController: rootViewController)
        
        if type == .RecentAlbum || type == .AllAlbum {
            //获取相册类型
            let currentType = type == .RecentAlbum ? PHAssetCollectionSubtype.smartAlbumRecentlyAdded : PHAssetCollectionSubtype.smartAlbumUserLibrary
            //取回相册数据
            let results = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype:currentType, options: nil)
            if results.count > 0 {
                //取回图片
                if let model = self.getModel(collection: results[0]) {
                    if model.count > 0 {
                        //初始化collectionview的流布局
                        let layout = PhotoCollectionViewController.configCustomCollectionLayout()
                        let controller = PhotoCollectionViewController(collectionViewLayout: layout)
                        //将图片数据传递给collectionView控制器去展示
                        controller.fetchResult = model as? PHFetchResult<PHObject>
                        //入栈collectionView视图控制器
                        self.pushViewController(controller, animated: false)
                    }
                }
            }
        }
    }
    
    //返回图片数据
    private func getModel(collection: PHAssetCollection) -> PHFetchResult<PHAsset>?{
        let fetchResult = PHAsset.fetchAssets(in: collection, options: PhotoFetchOptions.shareInstance)
        if fetchResult.count > 0 {
            return fetchResult
        }
        return nil
    }
   
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //PhotoCollectionViewController会调用这个方法
    func imageSelectFinish(){
        if self.imageSelectDelegate != nil {
            //关闭当前控制器
            self.dismiss(animated: true, completion: nil)
            //调用上一个视图控制器onImageSelectFinished方法，完成图片选择。
            self.imageSelectDelegate?.onImageSelectFinished(images: PhotoImage.instance.selectedImage)
        }
    }
    
    
    

}
