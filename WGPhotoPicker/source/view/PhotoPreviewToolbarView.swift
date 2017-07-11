//
//  PhotoPreviewToolbarView.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/9.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit

protocol PhotoPreviewToolbarViewDelegate: class {
    func onToolbarBackArrowClicked();
    func onSelected(select:Bool)
}

class PhotoPreviewToolbarView: UIView {
    //将PhotoPreviewViewController设置为当前代理
    weak var delegate: PhotoPreviewToolbarViewDelegate?
    //将PhotoPreviewViewController设置为当前代理
    weak var sourceDelegate: PhotoPreviewViewController?
    
    //checkbox的背景图片
    private var checkboxBg: UIImageView?
    //checkbox按钮
    private var checkbox: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configView()
    }
    //配置当前视图
    private func configView(){
        self.backgroundColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)
        
        // 初始化返回按钮
        let backArrow = UIButton(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
        //设置返回按钮的图片
        let backArrowImage = UIImage(named: "arrow_back")
        backArrow.setImage(backArrowImage, for: UIControlState.normal)
        //绑定返回按钮事件
        backArrow.addTarget(self, action: #selector(PhotoPreviewToolbarView.eventBackArrow), for: .touchUpInside)
        //将返回按钮添加上视图
        self.addSubview(backArrow)
        
        //工具栏上的选择框
        let padding: CGFloat = 10
        let checkboxWidth: CGFloat = 30
        let checkboxHeight = checkboxWidth
        let checkboxPositionX = self.bounds.width - checkboxWidth - padding
        let checkboxPositionY = (self.bounds.height - checkboxHeight) / 2
        
        self.checkbox = UIButton(type: .custom)
        checkbox!.frame = CGRect(x:checkboxPositionX,y: checkboxPositionY,width: checkboxWidth,height: checkboxHeight)
        //checkbox按钮的点击事件
        checkbox!.addTarget(self, action: #selector(PhotoPreviewToolbarView.eventCheckbox(sender:)), for: .touchUpInside)
        //未选中时的图片，默认
        let checkboxFront = UIImageView(image: UIImage(named: "picture_unselect"))
        checkboxFront.contentMode = .scaleAspectFill
        checkboxFront.frame = checkbox!.bounds
        checkbox!.addSubview(checkboxFront)
        //选中了的图片
        self.checkboxBg = UIImageView(image: UIImage(named: "picture_select"))
        checkboxBg!.contentMode = .scaleAspectFill
        checkboxBg!.frame = checkbox!.bounds
        checkboxBg!.isHidden = true
        
        self.checkbox!.addSubview(checkboxBg!)
        
        self.addSubview(checkbox!)
    }
    
    //返回按钮事件
    func eventBackArrow(){
        if let delegate = self.delegate {
            delegate.onToolbarBackArrowClicked()
        }
    }
    
    func setSelect(select:Bool){
        self.checkboxBg!.isHidden = !select
        self.checkbox!.isSelected = select
    }
    //点击顶部选中按钮时的事件对应的方法
    func eventCheckbox(sender: UIButton){
        //若按钮时，是否被选择了，是，则将其设回没选择中，否，则选中其。
        if sender.isSelected {
            sender.isSelected = false
            self.checkboxBg!.isHidden = true
            if let delegate = self.delegate {
                //调用代理PhotoPreviewViewController的onSelected
                delegate.onSelected(select: false)
            }
        } else {
            //未选中
            if let _ = self.sourceDelegate {
                //判断是否超过，最大选择数
                if PhotoImage.instance.selectedImage.count >= PhotoPickerController.imageMaxSelectedNum - PhotoPickerController.alreadySelectedImageNum {
                    return self.showSelectErrorDialog()
                }
            }
            //如果图片数未超过最大图片数时，就设置为选中。
            sender.isSelected = true
            self.checkboxBg!.isHidden = false
            //先缩小背景图片为原大小的0.8,然后，过0.5秒后，再还原。
            self.checkboxBg!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 8, options: [UIViewAnimationOptions.curveEaseIn], animations: { () -> Void in
                self.checkboxBg!.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: nil)
            //调用代理PhotoPreviewViewController的onSelected
            if let delegate = self.delegate {
                delegate.onSelected(select: true)
            }
        }
    }
    //弹出错误信息
    private func showSelectErrorDialog() {
        if self.sourceDelegate != nil {
            let less = PhotoPickerController.imageMaxSelectedNum - PhotoPickerController.alreadySelectedImageNum
            
            
            let range = PhotoPickerConfig.ErrorImageMaxSelect.range(of:"#")
            var error = PhotoPickerConfig.ErrorImageMaxSelect
            error.replaceSubrange(range!, with: String(less))
            
            let alert = UIAlertController.init(title: nil, message: error, preferredStyle: UIAlertControllerStyle.alert)
            let confirmAction = UIAlertAction(title: PhotoPickerConfig.ButtonConfirmTitle, style: .default, handler: nil)
            alert.addAction(confirmAction)
            self.sourceDelegate?.present(alert, animated: true, completion: nil)
        }
    }

}
