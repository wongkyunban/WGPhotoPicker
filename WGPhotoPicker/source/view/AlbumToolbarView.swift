//
//  AlbumToolbarView.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/8.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit

protocol AlbumToolbarViewDelegate: class{
    func onFinishedButtonClicked()
}

//选择图片时，底部的工具栏
class AlbumToolbarView: UIView {
    
    var doneNumberAnimationLayer: UIView?
    var labelTextView: UILabel?
    var buttonDone: UIButton?
    var doneNumberContainer: UIView?
    //接受上个控制器，作为本视图的代理
    weak var delegate: AlbumToolbarViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    private func setupView(){
        //设置底部工具栏的背景颜色
        self.backgroundColor = UIColor.white
        let bounds = self.bounds
        let width = bounds.width
        let toolbarHeight = bounds.height
        let buttonWidth: CGFloat = 40
        let buttonHeight: CGFloat = 40
        let padding:CGFloat = 5
        
        // 初始化一个按钮
        self.buttonDone = UIButton(type: .custom)
        //设置按钮的布局
        buttonDone!.frame = CGRect(x: width - buttonWidth - padding, y:(toolbarHeight - buttonHeight) / 2, width: buttonWidth, height: buttonHeight)
        //设置按钮的标题
        buttonDone!.setTitle(PhotoPickerConfig.ButtonDone, for: .normal)
        //按钮的字体大小
        buttonDone!.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        //设置字体颜色
        buttonDone!.setTitleColor(UIColor.black, for: .normal)
        //设置按钮点击事件
        buttonDone!.addTarget(self, action: #selector(AlbumToolbarView.eventDoneClicked), for: .touchUpInside)
        buttonDone!.isEnabled = true
        //设置按钮不能点击的字体颜色
        buttonDone!.setTitleColor(UIColor.gray, for: .disabled)
        //将按钮添加上布局
        self.addSubview(self.buttonDone!)
        
        // done number
        let labelWidth:CGFloat = 20
        let labelX = buttonDone!.frame.minX - labelWidth
        let labelY = (toolbarHeight - labelWidth) / 2
        //初始化显示数字的容器
        self.doneNumberContainer = UIView(frame: CGRect(x:labelX,y: labelY,width: labelWidth, height: labelWidth))
        let labelRect = CGRect(x:0, y:0, width: labelWidth, height: labelWidth)
        //形成一个绿色的圆
        self.doneNumberAnimationLayer = UIView.init(frame: labelRect)
        self.doneNumberAnimationLayer!.backgroundColor = UIColor.init(red: 7/255, green: 179/255, blue: 20/255, alpha: 1)
        //形成圆很重要的一步
        self.doneNumberAnimationLayer!.layer.cornerRadius = labelWidth / 2
        //在容器上叠加这个绿色的圆
        doneNumberContainer!.addSubview(self.doneNumberAnimationLayer!)
        //设置显示数字的label
        self.labelTextView = UILabel(frame: labelRect)
        //居中对齐
        self.labelTextView!.textAlignment = .center
        //透明背景
        self.labelTextView!.backgroundColor = UIColor.clear
        //字体白色
        self.labelTextView!.textColor = UIColor.white
        //在圆上添加这个数字
        doneNumberContainer!.addSubview(self.labelTextView!)
        
        //初始化时先隐藏这个显示数字的地方
        doneNumberContainer?.isHidden = true
        //将这个显示数字添置上视图
        self.addSubview(self.doneNumberContainer!)
        
        // 添加分割线
        let divider = UIView(frame: CGRect(x:0, y:0, width:width, height:1))
        //分割线颜色
        divider.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.15)
        //将分割线放上视图
        self.addSubview(divider)
    }
    
    //完成按钮的点击事件
    func eventDoneClicked(){
        if let delegate = self.delegate {
            //代理来完成这个点击事件
            delegate.onFinishedButtonClicked()
        }
    }
    //设置已选择的图片总数
    func changeNumber(number:Int){
        self.labelTextView?.text = String(number)
        if number > 0 {
            //已有选择了的图，则激活完成按钮
            self.buttonDone?.isEnabled = true
            //数字处也显示出来
            self.doneNumberContainer?.isHidden = false
            //缩小绿色圆为原来的一半
            self.doneNumberAnimationLayer!.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            //0.5秒后，恢复原状，达到动画的效果
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                self.doneNumberAnimationLayer!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }, completion: nil)
        } else {
            //没有已选中的图片则按钮设置为不可用，并隐藏显示数字处
            self.buttonDone?.isEnabled  = false
            self.doneNumberContainer?.isHidden = true
        }
    }
    
}
