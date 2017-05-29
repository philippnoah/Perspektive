//
//  Data.swift
//  Perspektive
//
//  Created by Philipp Eibl on 4/30/17.
//  Copyright © 2017 Philipp Eibl. All rights reserved.
//

import Foundation
import UIKit
import EventKit

class Year: UIView {
    var months: [Month] = []
    var eventViews: [EventView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if view.isKind(of: Month.self) {
            (view as! Month).parentYear = 2017
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Month: UIView {
    var parentYear: Int!
    var count: Int!
    var days: [Day] = []
    var eventViews: [EventView] = []
    var daysAreVisible = false
    var countLabel: UILabel!
    var layer1: CALayer!
    var hasEventLayer: CALayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(count: Int, x: CGFloat) {
        self.init(frame: CGRect(x: x, y: 0, width: 1, height: (UIScreen.main.bounds.height/2)))
        self.count = count
        countLabel = UILabel()
        countLabel.text = Calendar.current.shortMonthSymbols[count]
        countLabel.font = UIFont(name: "Quicksand-Bold", size: 16)
        countLabel.frame.size = CGSize(width: 100, height: 30)
        countLabel.frame.origin.x = 5
        countLabel.frame = countLabel.frame.integral
        self.addSubview(countLabel)
        
        self.layer1 = CALayer()
        layer1.frame.size = CGSize(width: 2, height: self.bounds.height)
        layer1.backgroundColor = UIColor.black.cgColor
        layer1.cornerRadius = 2
        self.layer.addSublayer(layer1)
        
        self.hasEventLayer = CALayer()
        hasEventLayer.frame = CGRect(x: countLabel.bounds.maxX, y: 0, width: 10, height: 10)
        hasEventLayer.cornerRadius = 5
        hasEventLayer.backgroundColor = UIColor.cyan.cgColor
        hasEventLayer.isHidden = true
        self.countLabel.layer.addSublayer(hasEventLayer)
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if view.isKind(of: Day.self) {
            (view as! Day).parentMonth = self
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.frame.width < 40 {
            countLabel.text = Calendar.current.veryShortMonthSymbols[count]
        } else if self.frame.width < 80 {
            countLabel.text = Calendar.current.shortMonthSymbols[count]
        } else {
            countLabel.text = Calendar.current.monthSymbols[count]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Day: UIView {
    var parentMonth: Month!
    var count: Int!
    var hours: [Hour] = []
    var eventViews: [EventView] = []
    var hoursAreVisible = false
    var countLabel: UILabel!
    var layer1: CALayer!
    var hasEventLayer: CALayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(count: Int, x: CGFloat) {
        self.init(frame: CGRect(x: x, y: 20, width: 1, height: (UIScreen.main.bounds.height/2)-40))
        self.count = count
        countLabel = UILabel()
        countLabel.text = String(count+1) + "."
        countLabel.font = UIFont(name: "Quicksand-Medium", size: 16)
        countLabel.textColor = UIColor(white: 0, alpha: 0.75)
        countLabel.sizeToFit()
        countLabel.frame.origin.x = 5
        self.addSubview(countLabel)
        
        self.layer1 = CALayer()
        layer1.frame.size = CGSize(width: 2, height: self.bounds.height)
        layer1.backgroundColor = UIColor(white: 0, alpha: 0.5).cgColor
        layer1.cornerRadius = 2
        self.layer.addSublayer(layer1)
        
        self.hasEventLayer = CALayer()
        hasEventLayer.frame = CGRect(x: countLabel.bounds.maxX, y: 5, width: 10, height: 10)
        hasEventLayer.cornerRadius = 5
        hasEventLayer.backgroundColor = UIColor.cyan.cgColor
        hasEventLayer.isHidden = true
        self.countLabel.layer.addSublayer(hasEventLayer)
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if view.isKind(of: Hour.self) {
            (view as! Hour).parentDay = self
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.frame.width > 36 {
            self.countLabel.isHidden = false
        } else {
            self.countLabel.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Hour: UIView {
    var parentDay: Day!
    var count: Int!
    var eventViews: [EventView] = []
    var countLabel: UILabel!
    var layer1: CALayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(count: Int, x: CGFloat) {
        self.init(frame: CGRect(x: x, y: 20, width: 1, height: (UIScreen.main.bounds.height/2)-80))
        self.count = count
        countLabel = UILabel()
        countLabel.text = String(count) + "h"
        countLabel.font = UIFont(name: "Quicksand-Medium", size: 16)
        countLabel.textColor = UIColor(white: 0, alpha: 0.5)
        countLabel.sizeToFit()
        countLabel.frame.origin.x = 5
        self.addSubview(countLabel)
        
        self.layer1 = CALayer()
        layer1.frame.size = CGSize(width: 2, height: self.bounds.height)
        layer1.backgroundColor = UIColor(white: 0, alpha: 0.25).cgColor
        layer1.cornerRadius = 2
        self.layer.addSublayer(layer1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.frame.width > 36 {
            self.countLabel.isHidden = false
        } else {
            self.countLabel.isHidden = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EventView: UILabel {
    var event: EKEvent!
    var month: Int = 0
    var day: Int = 0
    var gesture: UITapGestureRecognizer!
    var viewController: ViewController?
    var identifier: String?
    var isNewEvent = false
    var countInMonth: Int?
    var countInDay: Int?
    var willBeDeleted = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red:0.00, green:0.95, blue:1.00, alpha:1.0)
        self.textColor = UIColor.white
        self.font = UIFont(name: "Quicksand-Bold", size: 18)
        self.isUserInteractionEnabled = true
        self.gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        self.addGestureRecognizer(gesture)
    }
    
    convenience init(event: EKEvent) {
        self.init(frame: CGRect.zero)
        self.event = event
        self.text = event.title
        self.identifier = event.eventIdentifier
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        
        let y2017 = Calendar.current.date(from: DateComponents(year: 2017))
        self.month = event.startDate.months(from: y2017!)
        self.day = event.startDate.days(from: Calendar.current.date(from: DateComponents(year: 2017, month: self.month+1, day: 1, hour: 0, second: 0))!)
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 0)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }

    override func layoutSubviews() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        super.layoutSubviews()
        if self.frame.width < self.frame.height {
            self.layer.cornerRadius = self.frame.width/2
        } else {
            self.layer.cornerRadius = self.frame.height/2

        }
    }
    
    func tapped() {
        viewController?.tapped(eventView: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Handle: UIView {
    var dragGesture = UIPanGestureRecognizer()
    var side: String?
    var contentLayer: CALayer!
    var barLayer: CALayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }
    
    convenience init(side: String) {
        self.init(frame: CGRect.zero)
        self.side = side
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentLayer = CALayer()
        contentLayer.frame = CGRect(x: self.frame.midX/2, y: self.frame.midY/2, width: self.frame.midX, height: self.frame.midY)
        contentLayer.cornerRadius = 11
        contentLayer.backgroundColor = UIColor(red:0.00, green:0.47, blue:0.49, alpha:1.0).cgColor
        self.layer.addSublayer(contentLayer)
        
        barLayer = CALayer()
        if side! == "left" {
            barLayer.frame = CGRect(x: self.center.x-1, y: 20, width: 2, height: 40)
        } else if side! == "right" {
            barLayer.frame = CGRect(x: self.center.x-1, y: -20, width: 2, height: 40)
        }
        barLayer.backgroundColor = UIColor(red:0.00, green:0.47, blue:0.49, alpha:1.0).cgColor
        //self.layer.addSublayer(barLayer)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EV2: UIView {
    var label: UILabel!
    var background: CAGradientLayer!
    var event: EKEvent!
    var month: Int!
    var day: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(event: EKEvent) {
        self.init(frame: CGRect.zero)
        self.event = event
        
        self.label.text = event.title
        
        let colorTop = UIColor(red:0.00, green:1.00, blue:1.00, alpha:1.0).cgColor
        let colorBottom = UIColor(red:0.00, green:0.75, blue:1.00, alpha:1.0).cgColor
        let gradient = CAGradientLayer()
        gradient.frame.size = CGSize(width: 100, height: 100)
        gradient.colors = [colorTop, colorBottom]
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.roundCorners([.bottomLeft, .topRight], radius: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EventTitleTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.08)
        self.layer.cornerRadius = 15
        self.font = UIFont(name: "Quicksand-Bold", size: 18)
        self.textColor = UIColor(red:0, green:0, blue:0, alpha:0.7)
        self.clipsToBounds = true
        self.clearButtonMode = .whileEditing
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 10, y: 0, width: bounds.width-50, height: bounds.height)
    }
    
    override func firstRect(for range: UITextRange) -> CGRect {
        return CGRect(x: 10, y: 0, width: bounds.width-50, height: bounds.height)
        
    }
    
    override func alignmentRect(forFrame frame: CGRect) -> CGRect {
        return CGRect(x: 10, y: 0, width: bounds.width-50, height: bounds.height)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 10, y: 0, width: bounds.width-50, height: bounds.height)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 10, y: 0, width: bounds.width-50, height: bounds.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}

extension CALayer {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.mask = mask
    }
}

