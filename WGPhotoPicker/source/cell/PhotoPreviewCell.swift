//
//  PhotoPreviewCell.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/8.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

protocol PhotoPreviewCellDelegate: class{
    func onImageSingleTap()
}

class PhotoPreviewCell: UICollectionViewCell, UIScrollViewDelegate {
	//按受传过来的图片数据
	var model: PHAsset?
	private var scrollView: UIScrollView?
	private var imageContainerView = UIView()
	private var imageView = UIImageView()
    //将PhotoPreviewViewController作为其代理
    weak var delegate: PhotoPreviewCellDelegate?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.configView()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.configView()
	}
    //配置scrollview
	func configView() {
		self.scrollView = UIScrollView(frame: self.bounds)
        //设置scrollview的bouncesZoom属性可以确保view的放缩比例超出设置比例范围时自动进行反弹。
		self.scrollView!.bouncesZoom = true
        //缩放2.5倍
		self.scrollView!.maximumZoomScale = 2.5
        //多点触控
		self.scrollView!.isMultipleTouchEnabled = true
        //设置scrollview的代理
		self.scrollView!.delegate = self
		self.scrollView!.scrollsToTop = false
        //不显示水平指示块
		self.scrollView!.showsHorizontalScrollIndicator = false
        //不显示垂直指示块
		self.scrollView!.showsVerticalScrollIndicator = false
		self.scrollView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.scrollView!.delaysContentTouches = false
		self.scrollView!.canCancelContentTouches = true
		self.scrollView!.alwaysBounceVertical = false
		self.addSubview(self.scrollView!)
		
		self.imageContainerView.clipsToBounds = true
		self.scrollView!.addSubview(self.imageContainerView)
		
		self.imageView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
		self.imageView.clipsToBounds = true
		self.imageContainerView.addSubview(self.imageView)
		//单击
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(PhotoPreviewCell.singleTap(tap:)))
        //双击
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(PhotoPreviewCell.doubleTap(tap:)))
		//设置2个点击点
		doubleTap.numberOfTapsRequired = 2
		singleTap.require(toFail: doubleTap)
		//添加手势
		self.addGestureRecognizer(singleTap)
		self.addGestureRecognizer(doubleTap)
	}
    
    
	func renderModel(asset: PHAsset) {
        
        //将图片数据和宽度作为参数，取回大图
		PhotoImageManager.sharedManager.getPhotoByMaxSize(asset: asset, size: self.bounds.width) { (image, info) -> Void in
			self.imageView.image = image
            //重新设定imageView的大小
			self.resizeImageView()
		}
	}
    //重新设定imageView的大小
	func resizeImageView() {
        self.imageContainerView.frame = CGRect(x:0, y:0, width: self.frame.width, height: self.imageContainerView.bounds.height)
		let image = self.imageView.image!
        
        
		if image.size.height / image.size.width > self.bounds.height / self.bounds.width {
			
			let height = floor(image.size.height / (image.size.width / self.bounds.width))
			var originFrame = self.imageContainerView.frame
			originFrame.size.height = height
			self.imageContainerView.frame = originFrame
		} else {
			var height = image.size.height / image.size.width * self.frame.width
			if height < 1 || height.isNaN {
				height = self.frame.height
			}
			height = floor(height)
			var originFrame = self.imageContainerView.frame
            originFrame.size.height = height
			self.imageContainerView.frame = originFrame
            self.imageContainerView.center = CGPoint(x:self.imageContainerView.center.x, y:self.bounds.height / 2)
		}
		
		if self.imageContainerView.frame.height > self.frame.height && self.imageContainerView.frame.height - self.frame.height <= 1 {
			
			var originFrame = self.imageContainerView.frame
			originFrame.size.height = self.frame.height
			self.imageContainerView.frame = originFrame
		}
		
        self.scrollView?.contentSize = CGSize(width: self.frame.width, height: max(self.imageContainerView.frame.height, self.frame.height))
		self.scrollView?.scrollRectToVisible(self.bounds, animated: false)
		self.scrollView?.alwaysBounceVertical = self.imageContainerView.frame.height > self.frame.height
		self.imageView.frame = self.imageContainerView.bounds
        
	}
	//单击
	func singleTap(tap:UITapGestureRecognizer) {
        if let delegate = self.delegate {
            //调用PhotoPreviewViewController代理的方法
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    delegate.onImageSingleTap()
                    
                }
            }
           
        }
	}
	//双击
    func doubleTap(tap:UITapGestureRecognizer) {
        
        if (self.scrollView!.zoomScale > 1.0) {
            // 状态还原
            self.scrollView!.setZoomScale(1.0, animated: true)
        } else {
            //放大
            let touchPoint = tap.location(in: self.imageView)
            let newZoomScale = self.scrollView!.maximumZoomScale
            let xsize = self.frame.size.width / newZoomScale
            let ysize = self.frame.size.height / newZoomScale
            
            self.scrollView!.zoom(to: CGRect(x: touchPoint.x - xsize/2, y: touchPoint.y-ysize/2, width: xsize, height: ysize), animated: true)
        }
	}
   // 要实现放大缩小功能，需要指定UIScrollView的允许缩放最大比例和最小比例（默认都是是1.0）。
   // 同时delegate属性指定一个委托类，委托类要继承UIScrollViewDelegate协议，并在委托类中实现viewForZooming方法。
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageContainerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0.0;
        self.imageContainerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    
}
