//
//  ViewController.swift
//  StockChart
//
//  Created by Mr_Yao on 2021/6/21.
//

import UIKit

class ViewController: UIViewController {

    var timeLineView: TimeLine?
    var chartRect: CGRect = CGRect(x: 100, y: 200, width: 200, height: 100)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        timeLineView = TimeLine(frame: chartRect)
        let modelArray = getTimeLineModelArray(getJsonDataFromFile("timeLineForDay")!)
        timeLineView!.dataT = modelArray!
        timeLineView!.isUserInteractionEnabled = true
        timeLineView!.backgroundColor = UIColor(red: 128.0, green: 0.0, blue: 128.0, alpha: 0.1)
        view.addSubview(timeLineView!)
    }
    
    func getTimeLineModelArray(_ json: [String: Any]) -> [TimeLineModel]? {
        var modelArray = [TimeLineModel]()
        let toComparePrice: CGFloat = 68.74
        guard let localJson = json["chartlist"] as? [[String: Any]] else {
            return nil
        }
        for element in localJson {
            let model = TimeLineModel()
            model.avgPirce = element["avg_price"] as! CGFloat
            model.price = element["current"] as! CGFloat
            model.volume = element["volume"] as! CGFloat
            model.rate = (model.price - toComparePrice) / toComparePrice
            model.preClosePx = 68.74
            modelArray.append(model)
        }

        return modelArray
    }
    
    func getJsonDataFromFile(_ fileName: String) -> [String: Any]? {
        let pathForResource = Bundle.main.path(forResource: fileName, ofType: "json")
        let content = try! String(contentsOfFile: pathForResource!, encoding: String.Encoding.utf8)
        let localData = content.data(using: String.Encoding.utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: localData, options: .mutableContainers)
            let dic = json as! [String: Any]
            return dic
        } catch _ {
            return nil
        }
        
    }
    

}

// MARK: view

class TimeLine: UIView {
    
    var timeLineLayer = CAShapeLayer()
    
    var maxPrice: CGFloat = 0
    var minPrice: CGFloat = 0
    var maxRatio: CGFloat = 0
    var minRatio: CGFloat = 0
    var maxVolume: CGFloat = 0
    var priceMaxOffset : CGFloat = 0
    var priceUnit: CGFloat = 0
    var volumeUnit: CGFloat = 0
    var volumeStep: CGFloat = 0
    var volumeWidth: CGFloat = 0
    public var countOfTimes = 240
    
    var positionModels: [TimeLineCoordModel] = []
    public var dataT: [TimeLineModel] = [] {
        didSet {
            self.drawTimeLineChart()
        }
    }
    
    var uperChartHeight: CGFloat {
        get {
            return frame.height * TimeLineStyle().uperChartHeightScale
        }
    }
    var lowerChartHeight: CGFloat {
        get {
            return frame.height * (1 - TimeLineStyle().uperChartHeightScale) - TimeLineStyle().xAxisHeitht
        }
    }
    var uperChartDrawAreaTop: CGFloat {
        get {
            return TimeLineStyle().viewMinYGap
        }
    }
    var uperChartDrawAreaBottom: CGFloat {
        get {
            return uperChartHeight - TimeLineStyle().viewMinYGap
        }
    }
    var lowerChartTop: CGFloat {
        get {
            return uperChartHeight + TimeLineStyle().xAxisHeitht
        }
    }
    
    public init(frame: CGRect, isFiveDay: Bool = false) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 绘图
    func drawTimeLineChart() {
        setMaxAndMinData()
        convertToPoints(data: dataT)
        timeLineLayer.removeFromSuperlayer()
        drawLineLayer(array: positionModels)
    }
    
    /// 求极限值
    func setMaxAndMinData() {
        if dataT.count > 0 {
            let toComparePrice = dataT[0].preClosePx
            for i in 0 ..< dataT.count {
                let entity = dataT[i]
                self.priceMaxOffset = self.priceMaxOffset > abs(entity.price - toComparePrice) ? self.priceMaxOffset : abs(entity.price - toComparePrice)
                self.maxVolume = self.maxVolume > entity.volume ? self.maxVolume : entity.volume
                self.maxPrice = maxPrice > entity.price ? maxPrice : entity.price
                self.minPrice = minPrice < entity.price ? minPrice : entity.price
            }
            self.maxPrice = toComparePrice + self.priceMaxOffset
            self.minPrice = toComparePrice - self.priceMaxOffset
            self.maxRatio = self.priceMaxOffset / toComparePrice
            self.minRatio = -self.maxRatio
            
        }
    }
    
    /// 转换为坐标数据
    func convertToPoints(data: [TimeLineModel]) {
        let maxDiff = self.maxPrice - self.minPrice
        if maxDiff > 0, maxVolume > 0 {
            priceUnit = (uperChartHeight - 2 * TimeLineStyle().viewMinYGap) / maxDiff
            volumeUnit = (lowerChartHeight - TimeLineStyle().volumeGap) / self.maxVolume
        }
        
        volumeStep = self.frame.width / CGFloat(countOfTimes)
        
        volumeWidth = volumeStep - volumeStep / 3.0
        self.positionModels.removeAll()
        for index in 0 ..< data.count {
            let centerX = volumeStep * CGFloat(index) + volumeStep / 2
            
            let xPosition = centerX
            let yPosition = (self.maxPrice - data[index].price) * priceUnit + self.uperChartDrawAreaTop
            let pricePoint = CGPoint(x: xPosition, y: yPosition)
            
            let avgYPosition = (self.maxPrice - data[index].avgPirce) * priceUnit + self.uperChartDrawAreaTop
            let avgPoint = CGPoint(x: xPosition, y: avgYPosition)
            
            let volumeHeight = data[index].volume * volumeUnit
            let volumeStartPoint = CGPoint(x: centerX, y: frame.height - volumeHeight)
            let volumeEndPoint = CGPoint(x: centerX, y: frame.height)
            
            var positionModel = TimeLineCoordModel()
            positionModel.pricePoint = pricePoint
            positionModel.avgPoint = avgPoint
            positionModel.volumeHeight = volumeHeight
            positionModel.volumeStartPoint = volumeStartPoint
            positionModel.volumeEndPoint = volumeEndPoint
            
            self.positionModels.append(positionModel)
        }
    }
    
    /// 分时线
    func drawLineLayer(array: [TimeLineCoordModel]) {
        let timeLinePath = UIBezierPath()
        timeLinePath.move(to: array.first!.pricePoint)
        for index in 1 ..< array.count {
            timeLinePath.addLine(to: array[index].pricePoint)
        }
        timeLineLayer.path = timeLinePath.cgPath
        timeLineLayer.lineWidth = 1
        timeLineLayer.strokeColor = UIColor.red.cgColor
        timeLineLayer.fillColor = UIColor.clear.cgColor
        
        // 填充颜色
        timeLinePath.addLine(to: CGPoint(x: array.last!.pricePoint.x, y: TimeLineStyle().uperChartHeightScale * frame.height))
        timeLinePath.addLine(to: CGPoint(x: array[0].pricePoint.x, y: TimeLineStyle().uperChartHeightScale * frame.height))
        
        
        self.layer.addSublayer(timeLineLayer)
        self.animatePoint.frame = CGRect(x: array.last!.pricePoint.x - 3/2, y: array.last!.pricePoint.y - 3/2, width: 3, height: 3)
    }
    
    // 分时图实时动态点（呼吸灯动画）
    lazy var animatePoint: CALayer = {
        let animatePoint = CALayer()
        self.layer.addSublayer(animatePoint)
        animatePoint.backgroundColor = UIColor.blue.cgColor
        animatePoint.cornerRadius = 1.5
        
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 3, height: 3)
        layer.backgroundColor = UIColor.blue.cgColor
        layer.cornerRadius = 1.5
        layer.add(self.getBreathingLightAnimate(2), forKey: nil)
        
        animatePoint.addSublayer(layer)
        
        return animatePoint
    }()
        
}

extension TimeLine {
    
    /// 获取呼吸灯动画
    private func getBreathingLightAnimate(_ time:Double) -> CAAnimationGroup {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = 3.5
        scaleAnimation.autoreverses = false
        scaleAnimation.isRemovedOnCompletion = true
        scaleAnimation.repeatCount = MAXFLOAT
        scaleAnimation.duration = time
        
        let opacityAnimation = CABasicAnimation(keyPath:"opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0
        opacityAnimation.autoreverses = false
        opacityAnimation.isRemovedOnCompletion = true
        opacityAnimation.repeatCount = MAXFLOAT
        opacityAnimation.duration = time
        opacityAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        let group = CAAnimationGroup()
        group.duration = time
        group.autoreverses = false
        group.isRemovedOnCompletion = false // 设置为false 在各种走势图切换后，动画不会失效
        group.fillMode = CAMediaTimingFillMode.forwards
        group.animations = [scaleAnimation, opacityAnimation]
        group.repeatCount = MAXFLOAT
        
        return group
    }
}

// Model

class TimeLineModel: Codable {
    
    public var time: String = ""
    public var price: CGFloat = 0
    public var current: CGFloat = 0
    public var avg_price: CGFloat = 0
    public var volume: CGFloat = 0
    public var days: [String] = []
    public var preClosePx: CGFloat = 0
    public var avgPirce: CGFloat = 0
    public var totalVolume: CGFloat = 0
    public var trade: CGFloat = 0
    public var rate: CGFloat = 0
    
    public init() { }
}
struct TimeLineCoordModel {

    var pricePoint: CGPoint = .zero
    var avgPoint: CGPoint = .zero
    var volumeHeight: CGFloat = 0
    
    var volumeStartPoint: CGPoint = .zero
    var volumeEndPoint: CGPoint = .zero

}

struct TimeLineStyle {
    var uperChartHeightScale: CGFloat = 0.7 // 70% 的空间是上部分的走势图
    
    var lineWidth: CGFloat = 1
    var frameWidth: CGFloat = 0.25
    
    var xAxisHeitht: CGFloat = 30
    var viewMinYGap: CGFloat = 15
    var volumeGap: CGFloat = 10
    
}

