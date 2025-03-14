//
//  Untitled.swift
//  WaveProgressHUD
//
//  Created by dev on 2/27/25.
//

import UIKit
import SnapKit

class WaveProgressView: UIView {
    // 进度值(0.0 - 1.0)
    private var _progress: CGFloat = 0.0
    var progress: CGFloat {
        get { return _progress }
        set {
            let oldValue = _progress
            _progress = min(max(0, newValue), 1.0)
            percentLabel.text = "\(Int(_progress * 100))%"
            
            // 刷新视图
            updateWaveLayer()
            
            // 如果进度达到1.0，停止动画并填满整个圆
            if _progress >= 1.0 {
                fillFullCircle()
                stopWaveAnimation()
                return
            }
            if _progress == 0.0 {
                waveLayer.path = nil
                stopWaveAnimation()
                return
            }
            
            // 只有在有进度变化且不在动画中时才启动波浪动画
            if !isAnimating && oldValue != _progress {
                startWaveAnimation()
            }
        }
    }
    
    private var _netspeed: Double = 0.0
    var netspeed: Double {
        set {
            _netspeed = newValue
            if _netspeed < 1.0 {
                let speedString = String(format: "%.2f KB/s", _netspeed * 1024)
                netspeedLabel.text = speedString
            }else{
                let speedString = String(format: "%.2f MB/s", _netspeed)
                netspeedLabel.text = speedString
            }
            
        }
        get {
            return _netspeed
        }
    }
    
    // 波浪参数
    private let waveHeight: CGFloat = 10.0
    private let waveSpeed: CGFloat = 0.15  // 降低波浪速度
    private var waveOffset: CGFloat = 0.0
    private var isAnimating: Bool = false
    
    // 圆形遮罩
    private let circleLayer = CAShapeLayer()
    
    // 波浪图层
    private let waveLayer = CAShapeLayer()
    
    // 背景图层
    private let backgroundLayer = CAShapeLayer()
    
    // 波浪颜色
    private let waveColor = UIColor.systemBlue
    
    // 进度标签
    private let percentLabel = UILabel()
    // 网速标签
    private let netspeedLabel = UILabel()
    
    // 显示器定时器
    private var displayLink: CADisplayLink?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        // 创建圆形背景
        backgroundLayer.fillColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        layer.addSublayer(backgroundLayer)
        
        // 创建波浪层
        waveLayer.fillColor = waveColor.cgColor
        layer.addSublayer(waveLayer)
        
        // 创建圆形遮罩层
        circleLayer.fillColor = UIColor.black.cgColor
        
        // 设置百分比标签
        percentLabel.textAlignment = .center
        percentLabel.textColor = .white
        percentLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        percentLabel.text = "0%"
        addSubview(percentLabel)
        percentLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-10)
            make.leading.trailing.equalToSuperview()
        }
        
        netspeedLabel.textAlignment = .center
        netspeedLabel.textColor = .white
        netspeedLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        netspeedLabel.text = "0 MB/s"
        addSubview(netspeedLabel)
        netspeedLabel.snp.makeConstraints { make in
            make.top.equalTo(self.percentLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新背景圆形
        let path = UIBezierPath(ovalIn: bounds)
        backgroundLayer.path = path.cgPath
        
        // 更新遮罩
        circleLayer.path = path.cgPath
        layer.mask = circleLayer
        
//        // 更新标签位置
//        percentLabel.frame = bounds
        
        // 更新波浪动画
        updateWaveLayer()
    }
    
    private func updateWaveLayer() {
        
        // 处理零进度情况
        guard _progress > 0 else {
           waveLayer.path = nil
//           percentLabel.textColor = waveColor
           return
        }
        
        let height = bounds.height
        let width = bounds.width
        
        // 确定水位线位置（从底部开始填充）
        let waterLevel = height * (1 - _progress)
        
        // 创建路径
        let path = UIBezierPath()
        
        // 移动到起点（左下角）
        path.move(to: CGPoint(x: 0, y: height))
        
        // 绘制直线到左侧水位点
        path.addLine(to: CGPoint(x: 0, y: waterLevel))
        
        // 绘制波浪路径
        var x: CGFloat = 0
        let waveLength: CGFloat = width
        
        while x <= width {
            // 使用正弦函数创建波浪效果
            let y = waterLevel + waveHeight * sin((x / waveLength) * 2 * .pi + waveOffset)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }
        
        // 绘制到右下角和底部，完成闭合
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        // 应用路径
        waveLayer.path = path.cgPath
        
        // 如果进度为100%，确保标签可见（改变文字颜色）
        if _progress >= 1.0 {
            percentLabel.textColor = UIColor.white
        } else {
            percentLabel.textColor = UIColor.white //waveColor
        }
    }
    
    // 新增方法：进度达到100%时填满整个圆
    private func fillFullCircle() {
        let circlePath = UIBezierPath(ovalIn: bounds)
        
        // 使用动画过渡到填满状态
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        waveLayer.path = circlePath.cgPath
        CATransaction.commit()
        
        // 改变标签颜色以确保在蓝色背景上可见
        percentLabel.textColor = UIColor.white
    }
    
    func startWaveAnimation() {
        // 如果已经在动画，不重复创建
        if isAnimating { return }
        
        // 如果进度已经达到1.0，不启动动画
        if _progress >= 1.0 { return }
        
        isAnimating = true
        
        // 创建显示链接，仅控制波浪效果的横向滚动
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveOffset))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stopWaveAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        isAnimating = false
    }
    
    @objc private func updateWaveOffset() {
        // 更新波浪偏移以创建移动效果
        waveOffset += waveSpeed
        
        // 只更新波浪的动画，不改变进度值
        updateWaveLayer()
    }
    
    deinit {
        stopWaveAnimation()
    }
}


