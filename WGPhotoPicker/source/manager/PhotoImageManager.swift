//
//  PhotoImageManager.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/8.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos


class PhotoImageManager: PHCachingImageManager {
    
    // singleton class
    static let sharedManager = PhotoImageManager()
    private override init() {super.init()}
    
    func getPhotoByMaxSize(asset: PHObject, size: CGFloat, completion: @escaping (UIImage?, [NSObject : AnyObject]?)->Void){
        
        //获得最在的迟寸，最大吾可以超过PhotoPickerConfig.PreviewImageMaxFetchMaxWidth设置的大小
        let maxSize = size > PhotoPickerConfig.PreviewImageMaxFetchMaxWidth ? PhotoPickerConfig.PreviewImageMaxFetchMaxWidth : size
        if let asset = asset as? PHAsset {
            //图片的高：宽
            let factor = CGFloat(asset.pixelHeight)/CGFloat(asset.pixelWidth)
            //屏幕分辨率
            let scale = UIScreen.main.scale
            //大图横向像素
            let pixcelWidth = maxSize * scale
            //根据图片的高宽比，用等比例的数学计算方式得出横向像素为pixcelWidth时的pixcelHeight
            let pixcelHeight = CGFloat(pixcelWidth) * factor
            //请求图片，并在回调中将数据传回。
            PhotoImageManager.sharedManager.requestImage(for: asset, targetSize: CGSize(width:pixcelWidth, height: pixcelHeight), contentMode: .aspectFit, options: nil, resultHandler: { (image, info) -> Void in
                
                if let info = info as? [String:AnyObject] {
                    //被取消
                    let canceled = info[PHImageCancelledKey] as? Bool
                    //filemanager或iCloud photo发生错误
                    let error = info[PHImageErrorKey] as? NSError
                    //当没有发生任何错误，并成功取回图片，立即调用回调函数
                    if canceled == nil && error == nil && image != nil {
                        completion(image,info as [NSObject : AnyObject]?)
                    }
                    
                    // 从 iCloud上下载图片
                    let isCloud = info[PHImageResultIsInCloudKey] as? Bool
                    if isCloud != nil && image == nil {
                        //图片请求参数
                        let options = PHImageRequestOptions()
                        //允许从通过网络下载
                        options.isNetworkAccessAllowed = true
                        //开始从iCloud上下载图片,成功后立即调用回调函数
                        PhotoImageManager.sharedManager.requestImageData(for: asset, options: options, resultHandler: { (data, dataUTI, oritation, info) -> Void in
                            
                            if let data = data {
                                
                                let resultImage = UIImage(data: data, scale: 0.1)
                                completion(resultImage,info as [NSObject : AnyObject]?)
                            }
                        })
                    }
                }
            })
        }
    }


}
