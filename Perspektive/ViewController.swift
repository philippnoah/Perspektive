//
//  ViewController.swift
//  Perspektive
//
//  Created by Philipp Eibl on 4/30/17.
//  Copyright © 2017 Philipp Eibl. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    //Objects
    var containerView = UIScrollView()
    var yearView = Year()
    var currentTime = UIView()
    var timeLabel = UILabel()
    var pinchGesture = UIPinchGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    var dragGesture = UIPanGestureRecognizer()
    var dragToZoomGesture = UIPanGestureRecognizer()
    var longPressGesture: UILongPressGestureRecognizer!
    var addEventButton = UIButton()
    let topEditModeContainer = UIView()
    let bottomEditModeContainer = UIView()
    var eventLocationLabel = UILabel()
    var editEventLabel = UILabel()
    var eventTitleTextField = EventTitleTextField()
    var startDateLabel = UILabel()
    var untilLabel = UILabel()
    var endDateLabel = UILabel()
    var deleteButton = UIButton()
    var cancelButton = UIButton()
    var saveButton = UIButton()
    var eventViewInFocus: EventView!
    var leftHandle: Handle!
    var rightHandle: Handle!
    var viewToDrag: UIView?
    var gestureTouch: UITouch?
    var dateFormatter: DateFormatter!
    var middleHour: Hour?
    
    //Variables
    var delta: CGFloat = 0
    var lastScale: CGFloat = 0
    var lastWidth: CGFloat = 0
    var middle: CGFloat = 0
    var y2017 = Calendar.current.date(from: DateComponents(year: 2017))!
    var minutesInYear: CGFloat = 0
    var minuteAsPercentage: CGFloat = 0
    var dontCallScrollViewDidScroll = false
    var longPressGestureLastLocation = CGPoint(x: 0, y: 0)
    var longPressStartedOnEventInFocus = false
    var eventHeight = CGFloat(60)
    var eventY: CGFloat = 70
    var sizePercentage = CGSize(width: 1, height: 1)
    var editModeIsOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        setVariables()
        addUIObjects()
        addGestures()
        retrieveEvents()
        zoomToCurrentDay()
        view.isUserInteractionEnabled = true
        
        //Add observer
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        //Add DateFormatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy | HH:mm"
        
        pinched()
    }
    
    func setVariables() {
        let y2018 = Calendar.current.date(from: DateComponents(year: 2018))!
        minutesInYear = CGFloat(y2018.minutes(from: y2017))
        minuteAsPercentage = view.frame.width/minutesInYear
    }
    
    func addUIObjects() {
        //Container
        containerView.frame.size = CGSize(width: view.frame.width, height: view.frame.height * (2/3))
        containerView.center = CGPoint(x: view.center.x, y: view.center.y + 40)
        containerView.bounces = false
        containerView.delegate = self
        containerView.clipsToBounds = true
        containerView.scrollIndicatorInsets.bottom = 40
        view.addSubview(containerView)
        
        //new Event button
        addEventButton.setTitle("Add", for: UIControlState.normal)
        addEventButton.setTitleColor(UIColor.cyan, for: UIControlState.normal)
        addEventButton.setImage(UIImage(named: "plusIcon"), for: .normal)
        addEventButton.frame = CGRect(x: view.frame.maxX-60, y: 45, width: 30, height: 30)
        addEventButton.addTarget(self, action: #selector(ViewController.addEvent), for: UIControlEvents.touchUpInside)
        addEventButton.isHidden = true
        view.addSubview(addEventButton)
        
        //Year
        addMonths()
        
        //Timer
        addCurrentTime()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.addCurrentTime), userInfo: nil, repeats: true)
        
        //Edit Mode
        addEditMode()
        
    }
    
    func keyboardNotification(notification: NSNotification) {
        self.isEditing = true
    }
    
    func addMonths() {
        yearView.frame = containerView.bounds
        containerView.addSubview(yearView)
        for monthCount in 0 ... 11 {
            let monthView = Month(count: monthCount, x: 0)
            yearView.months.append(monthView)
            addDaysTo(month: monthView)
        }
        loadMonths()
    }
    
    func addDaysTo(month: Month) {
        let monthAsDate = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1))
        let range = Calendar.current.range(of: .day, in: .month, for: monthAsDate!)!
        
        for dayCount in 0...range.count-1 {
            let dayView = Day(count: dayCount, x: 0)
            month.days.append(dayView)
            addHoursTo(day: dayView)
        }
    }
    
    func addHoursTo(day: Day) {
        for hourCount in 0...23 {
            let hourView = Hour(count: hourCount, x: 0)
            hourView.parentDay = day
            hourView.count = hourCount
            day.hours.append(hourView)
        }
    }
    
    func addGestures() {
        pinchGesture.addTarget(self, action: #selector(ViewController.pinched))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        tapGesture.addTarget(self, action: #selector(ViewController.tap))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        dragGesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragged))
        dragGesture.delegate = self
        containerView.addGestureRecognizer(dragGesture)
        
        dragToZoomGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedToZoom))
        dragToZoomGesture.delegate = self
        dragToZoomGesture.minimumNumberOfTouches = 2
        containerView.addGestureRecognizer(dragToZoomGesture)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        containerView.addGestureRecognizer(longPressGesture)
    }
    
    func addCurrentTime() {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        
        // get current day instead and get seconds since current day
        //        currentTime.frame.origin.x += currentTime.frame.origin.x * delta
        let minutes = CGFloat(Date().minutes(from: y2017))
        let x = minutes * minuteAsPercentage
        currentTime.frame.origin.x = x
        timeLabel.text = df.string(from: Date())
        
        if !yearView.subviews.contains(currentTime) {
            currentTime.backgroundColor = UIColor.red
            currentTime.layer.cornerRadius = 2
            
            let minutes = CGFloat(Date().minutes(from: y2017))
            let x = minutes * minuteAsPercentage
            currentTime.frame = CGRect(x: x, y: yearView.subviews[0].frame.minY, width: 2, height: view.frame.height/2)
            
            let currentTimeCircle = CALayer()
            currentTimeCircle.frame = CGRect(x: -5, y: 10, width: 12, height: 12)
            currentTimeCircle.cornerRadius = 7
            currentTimeCircle.backgroundColor = UIColor.red.cgColor
            
            yearView.addSubview(currentTime)
            currentTime.layer.addSublayer(currentTimeCircle)
            
            timeLabel.text = df.string(from: Date())
            timeLabel.textColor = UIColor.red
            timeLabel.frame = CGRect(x: 0, y: -30, width: 50, height: 40)
            timeLabel.textAlignment = .center
            timeLabel.center.x = 0
            timeLabel.font = UIFont(name: "Quicksand-Medium", size: 10)
            currentTime.addSubview(timeLabel)
        }
    }
    
    func addEditMode() {
        //container
        
        topEditModeContainer.frame = CGRect(x: 0, y: -containerView.frame.minY, width: view.frame.width, height: containerView.frame.minY)
        view.addSubview(topEditModeContainer)
        
        bottomEditModeContainer.frame = CGRect(x: 0, y: view.frame.maxY, width: view.frame.width, height: view.frame.maxY - 70)
        view.addSubview(bottomEditModeContainer)
        
        //location label
        editEventLabel.text = "Edit Event"
        editEventLabel.font = UIFont(name: "Quicksand-Bold", size: 18)
        editEventLabel.sizeToFit()
        editEventLabel.center.x = view.center.x
        editEventLabel.frame.origin.y = 30
        editEventLabel.textAlignment = .center
        editEventLabel.frame = editEventLabel.frame.integral
        topEditModeContainer.addSubview(editEventLabel)
        
        //location label
        eventLocationLabel.text = ""
        eventLocationLabel.font = UIFont(name: "Quicksand-Medium", size: 14)
        eventLocationLabel.textColor = UIColor(red:0.80, green:0.80, blue:0.80, alpha:1.0)
        eventLocationLabel.frame = CGRect(x: 25, y: 55, width: 200, height: 20)
        topEditModeContainer.addSubview(eventLocationLabel)
        
        //Title TextField
        eventTitleTextField.placeholder = "Title"
        eventTitleTextField.frame = CGRect(x: 20, y: 65, width: view.frame.width-40, height: 45)
        eventTitleTextField.delegate = self
        topEditModeContainer.addSubview(eventTitleTextField)
        
        //start date
        startDateLabel.text = "Start Date"
        startDateLabel.textColor = UIColor.lightGray
        startDateLabel.font = UIFont(name: "Quicksand-Medium", size: 16)
        startDateLabel.frame = CGRect(x: 25, y: 110, width: 150, height: 40)
        topEditModeContainer.addSubview(startDateLabel)
        //add round border (apple watch)
        
        //until label
        untilLabel.text = "until"
        untilLabel.font = UIFont(name: "Quicksand-Medium", size: 16)
        untilLabel.textAlignment = .center
        untilLabel.textColor = UIColor.darkGray
        untilLabel.sizeToFit()
        untilLabel.frame.origin = CGPoint(x: view.frame.midX-untilLabel.bounds.midX, y: 120)
        topEditModeContainer.addSubview(untilLabel)
        
        //end date
        endDateLabel.text = "End Date"
        endDateLabel.textColor = UIColor.lightGray
        endDateLabel.font = UIFont(name: "Quicksand-Medium", size: 16)
        endDateLabel.frame = CGRect(x: eventTitleTextField.frame.maxX-155, y: 110, width: 150, height: 40)
        endDateLabel.textAlignment = .right
        topEditModeContainer.addSubview(endDateLabel)
        
        deleteButton.setTitle("Delete", for: UIControlState.normal)
        deleteButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        deleteButton.titleLabel?.font = UIFont(name: "Quicksand-Bold", size: 18)
        deleteButton.backgroundColor = UIColor.red
        deleteButton.layer.cornerRadius = 25
        deleteButton.frame = CGRect(x: 20, y: 0, width: 100, height: 50)
        deleteButton.addTarget(self, action: #selector(ViewController.deleteButtonPressed), for: .touchUpInside)
        deleteButton.isHidden = true
        bottomEditModeContainer.addSubview(deleteButton)
        
        cancelButton.setTitle("Cancel", for: UIControlState.normal)
        cancelButton.setTitleColor(UIColor.lightGray, for: UIControlState.normal)
        cancelButton.titleLabel?.font = UIFont(name: "Quicksand-Bold", size: 20)
        cancelButton.frame = CGRect(x: bottomEditModeContainer.bounds.midX-40, y: 10, width: 80, height: 40)
        cancelButton.addTarget(self, action: #selector(ViewController.cancelButtonPressed), for: .touchUpInside)
        bottomEditModeContainer.addSubview(cancelButton)
        
        saveButton.setTitle("Save", for: UIControlState.normal)
        saveButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        saveButton.titleLabel?.font = UIFont(name: "Quicksand-Bold", size: 18)
        saveButton.backgroundColor = UIColor.green
        saveButton.layer.cornerRadius = 25
        saveButton.frame = CGRect(x: bottomEditModeContainer.bounds.maxX - 120, y: 0, width: 100, height: 50)
        saveButton.addTarget(self, action: #selector(ViewController.saveButtonPressed), for: .touchUpInside)
        bottomEditModeContainer.addSubview(saveButton)
        
        leftHandle = Handle(side: "left")
        leftHandle.frame.size = CGSize(width: 40, height: 40)
        leftHandle.isHidden = true
        containerView.addSubview(leftHandle)
        
        rightHandle = Handle(side: "right")
        rightHandle.frame.size = CGSize(width: 40, height: 40)
        rightHandle.isHidden = true
        containerView.addSubview(rightHandle)
    }
    
    func zoomToCurrentDay() {
        self.delta = 1
        UIView.animate(withDuration: 0.6, animations: ({
            self.yearView.frame.size.width = self.view.frame.width * 450
            self.pinched()
            let minutes = CGFloat(Date().minutes(from: self.y2017))
            let x = minutes * self.minuteAsPercentage
            self.containerView.contentOffset.x = x - self.view.frame.width/2
        }), completion: ({ _ in
            self.pinched()
        }))
    }
    
    func retrieveEvents() {
        let eventStore = EKEventStore()
        if EKEventStore.authorizationStatus(for: .event) != .authorized || EKEventStore.authorizationStatus(for: .reminder) != .authorized {
            //is redundent
            eventStore.requestAccess(to: .event, completion: { Bool, Error in
                eventStore.requestAccess(to: .reminder, completion: { Bool, Error in
                    self.retrieveEvents()
                })
            })
        } else {
            var calendars = eventStore.calendars(for: .event)
            calendars.append(contentsOf: eventStore.calendars(for: .reminder))
            
            DispatchQueue.main.async {
                //set to current month
                let yearStart = Calendar.current.date(from: DateComponents(year: 2017))
                let yearEnd = Calendar.current.date(from: DateComponents(year: 2018))
                let predicate = eventStore.predicateForEvents(withStart: yearStart!, end: yearEnd!, calendars: calendars)
                let events = eventStore.events(matching: predicate)
                
                for event in events {
                    let eventView = EventView(event: event)
                    self.yearView.months[eventView.month].eventViews.append(eventView)
                    eventView.countInMonth = self.yearView.months[eventView.month].eventViews.count-1
                    self.yearView.months[eventView.month].days[eventView.day].eventViews.append(eventView)
                    eventView.countInDay = self.yearView.months[eventView.month].days[eventView.day].eventViews.count-1
                }
                
            }
        }
        
    }
    
    func isOnScreen(v: UIView) -> Bool {
        let foo = view.convert(v.frame, from: v.superview)
        if (view.bounds.contains(foo)) || (view.bounds.intersection(foo).width > 0) {
            return true
        }
        return false
    }
    
    //MARK: ---------------------------------------------------- pinched -----------------------------------------------------------------------------
    
    func pinched() {
        //MARK: First Time
        if pinchGesture.state == .began {
            lastScale = pinchGesture.scale
            let aX = pinchGesture.location(ofTouch: 0, in: self.view).x
            let bX = pinchGesture.location(ofTouch: 1, in: self.view).x
            middle = (aX + bX) / 2
            return
        }
        
        //MARK: Calculate Delta-X
        delta = pinchGesture.scale - lastScale
        
        //MARK: Stay Save
        if yearView.frame.size.width + (yearView.frame.size.width * delta) <= view.frame.width {
            delta = 0
        } else if (yearView.frame.size.width + (yearView.frame.size.width * delta))/12/28/8 >= view.frame.width {
            return
        }
        
        if editModeIsOn && delta < 0 && (yearView.frame.size.width + (yearView.frame.size.width * delta))/12/32 <= view.frame.width {
            return
        }
        
        //MARK: Hide indicator
        containerView.indicatorStyle = .white
        
        //MARK: Content-Size
        dontCallScrollViewDidScroll = true
        containerView.contentSize.width = yearView.frame.width + (yearView.frame.width * delta)
        dontCallScrollViewDidScroll = false
        
        //MARK: Content-Offset
        let calc = (containerView.contentOffset.x + middle) * CGFloat(delta)
        var scrollBounds = containerView.bounds
        scrollBounds.origin = CGPoint(x: CGFloat(containerView.contentOffset.x) + calc, y: 0)
        containerView.bounds = scrollBounds
        
        //MARK: Time
        minuteAsPercentage = yearView.frame.width/minutesInYear
        
        //MARK: Resize UI
        yearView.frame.size.width += yearView.frame.size.width * delta
        
        //map
        minuteAsPercentage = yearView.frame.width/minutesInYear
        
        //Months
        resize()
        
        //MARK: Timer
        addCurrentTime()
        
        //eventInFocus
        resizeEventInFocus()
        
        //hide and show addButton
        if yearView.frame.width/12/31 >= view.frame.width {
            addEventButton.isHidden = false
        } else {
            addEventButton.isHidden = true
        }
        
        //MARK: Show indicator
        containerView.indicatorStyle = .black
        
        //Reset Vars
        lastScale = pinchGesture.scale
        lastWidth = containerView.contentSize.width
    }
    
    //MARK: -------------------------------------------------------------- resize -------------------------------------------------------------------
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !dontCallScrollViewDidScroll {
            delta = 0
            resize()
        }
    }
    
    func resize() {
        let ywd12 = yearView.frame.width/12
        let containerOffset = containerView.contentOffset
        
        for month in yearView.months {
            let monthFrame = month.frame
            month.frame.origin.x += monthFrame.origin.x * delta
            month.frame.size.width += monthFrame.size.width * delta
            
            let monthStart = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1))!
            var minutes = CGFloat(monthStart.minutes(from: y2017))
            let x = minuteAsPercentage * minutes
            
            minutes = CGFloat(Calendar.current.date(from: DateComponents(year: 2017, month: month.count+2))!.minutes(from: monthStart))
            let width = minuteAsPercentage * minutes
            month.frame = CGRect(x: x, y: (containerView.frame.height-view.frame.height/2)/2, width: width, height: view.frame.height/2)
            if ywd12 > view.frame.width-1 && isOnScreen(v: month) {
                if monthFrame.minX <= containerOffset.x {
                    month.countLabel.frame.origin.x = containerView.convert(containerOffset, to: month).x + 5
                }
                resizeDaysOf(month: month)
                month.daysAreVisible = true
            } else if month.daysAreVisible == true {
                month.countLabel.frame.origin.x = 5
                for day in month.days {
                    day.removeFromSuperview()
                }
                month.daysAreVisible = false
            }
        }
    }
    
    func resizeDaysOf(month: Month) {
        let containerOffset = containerView.contentOffset
        let ywd1230 = yearView.frame.width/12/30
        let monthStart = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1))
        
        for day in month.days {
            let dayFrame = day.frame
            if month.subviews.contains(day) {
                day.frame.origin.x += dayFrame.origin.x * delta
                day.frame.size.width += dayFrame.size.width * delta
                
                if ywd1230 > view.frame.width-1 && isOnScreen(v: day) {
                    if month.convert(dayFrame.origin, to: containerView).x <= containerOffset.x {
                        day.countLabel.frame.origin.x = containerView.convert(containerOffset, to: day).x + 5
                    }
                    resizeHoursOf(day: day)
                    day.hoursAreVisible = true
                } else if day.hoursAreVisible == true {
                    day.countLabel.frame.origin.x = 5
                    for hour in day.hours {
                        hour.removeFromSuperview()
                    }
                    day.hoursAreVisible = false
                    for eventView in day.eventViews {
                        eventView.removeFromSuperview()
                    }
                }
            } else {
                let dayStart = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1, day: day.count+1))
                let dayEnd = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1, day: day.count+2))
                var minutes = CGFloat(dayStart!.minutes(from: monthStart!))
                let x = minuteAsPercentage * minutes
                minutes = CGFloat(dayEnd!.minutes(from: dayStart!))
                let width = minuteAsPercentage * minutes
                day.frame.origin.x = x
                day.frame.size.width = width
                if day.eventViews.count > 0 {
                    day.hasEventLayer.isHidden = false
                }
                month.addSubview(day)
            }
        }
    }
    
    func resizeHoursOf(day: Day) {
        for hour in day.hours {
            if day.subviews.contains(hour) {
                hour.frame.origin.x += hour.frame.origin.x * delta
                hour.frame.size.width += hour.frame.size.width * delta
                if hour.frame.contains(view.convert(view.center, to: hour.superview)) {
                    middleHour = hour
                }
            } else {
                let dayStart = Calendar.current.date(from: DateComponents(year: 2017, month: day.parentMonth.count+1, day: day.count+1))
                let hourStart = Calendar.current.date(from: DateComponents(year: 2017, month: day.parentMonth.count+1, day: day.count+1, hour: hour.count))
                let hourEnd = Calendar.current.date(from: DateComponents(year: 2017, month: day.parentMonth.count+1, day: day.count+1, hour: hour.count+1))
                var minutes = CGFloat(hourStart!.minutes(from: dayStart!))
                let x = minuteAsPercentage * minutes
                
                minutes = CGFloat(hourEnd!.minutes(from: hourStart!))
                let width = minuteAsPercentage * minutes
                hour.frame.origin.x = x
                
                hour.frame.size.width = width
                day.addSubview(hour)
                day.hoursAreVisible = true
            }
        }
        
        var lastEventView: EventView!
        var maxX = CGFloat(0)
        for eventView in day.eventViews {
            
            if day.subviews.contains(eventView) {
                
                
                eventView.frame.origin.x += eventView.frame.origin.x * delta
                eventView.frame.origin.y = eventY
                eventView.frame.size.width += eventView.frame.size.width * delta
                eventView.frame.size.height = eventHeight
                
                //there has to be a better way
                if eventView.frame.minX > maxX - 5 {
                    //deos not account for three events in a row
                    maxX = eventView.frame.maxX
                } else {
                    eventView.frame.origin.y = lastEventView.frame.maxY + 5
                }
                
            } else if !eventView.willBeDeleted {
                let minutes = eventView.event.startDate.minutes(from: Calendar.current.date(from: DateComponents(year: 2017, month: day.parentMonth.count+1, day: day.count+1))!)
                let duration = eventView.event.endDate.minutes(from: eventView.event.startDate)
                let x = minuteAsPercentage * CGFloat(minutes)
                eventView.frame = CGRect(x: x, y: eventY, width: CGFloat(duration) * minuteAsPercentage, height: eventHeight)
                eventView.viewController = self
                day.addSubview(eventView)
            }
            lastEventView = eventView
        }
    }
    
    func loadMonths() {
        for month in yearView.months {
            let monthStart = Calendar.current.date(from: DateComponents(year: 2017, month: month.count+1))!
            var minutes = CGFloat(monthStart.minutes(from: y2017))
            let x = minuteAsPercentage * minutes
            
            minutes = CGFloat(Calendar.current.date(from: DateComponents(year: 2017, month: month.count+2))!.minutes(from: monthStart))
            let width = minuteAsPercentage * minutes
            month.frame = CGRect(x: x, y: (containerView.frame.height-view.frame.height/2)/2, width: width, height: view.frame.height/2)
            
            if month.eventViews.count > 0 {
                month.hasEventLayer.isHidden = false
            }
            yearView.addSubview(month)
        }
    }
    
    func resizeEventInFocus() {
        if editModeIsOn && eventViewInFocus != nil {
            if eventViewInFocus.isNewEvent {
                eventViewInFocus.frame.origin.x += eventViewInFocus.frame.origin.x * delta
                eventViewInFocus.frame.size.width += eventViewInFocus.frame.size.width * delta
            }
            leftHandle.center = eventViewInFocus.superview!.convert(CGPoint(x: eventViewInFocus.frame.minX, y: eventViewInFocus.frame.midY), to: containerView)
            rightHandle.center = eventViewInFocus.superview!.convert(CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY), to: containerView)
        }
    }
    
    //MARK: ------------------------------------------------------------ tapped -----------------------------------------------------------------------------
    
    func tapped(eventView: EventView) {
        if !(eventViewInFocus?.isNewEvent ?? false) {// umgekehrte umgekehrte umgekehrte psychologie
            edit(eventView: eventView)
        }
    }
    
    func edit(eventView: EventView) {
        eventViewInFocus?.layer.opacity = 1
        eventViewInFocus = eventView
        eventTitleTextField.text = eventView.event.title
        startDateLabel.text = dateFormatter.string(from: eventViewInFocus.event.startDate)
        endDateLabel.text = dateFormatter.string(from: eventViewInFocus.event.endDate)
        leftHandle.center = containerView.convert(CGPoint(x: eventViewInFocus.frame.origin.x, y: eventViewInFocus.center.y), from: eventViewInFocus.superview)
        leftHandle.isHidden = false
        let endPoint = CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY)
        rightHandle.center = containerView.convert(endPoint, from: eventViewInFocus.superview)
        rightHandle.isHidden = false
        editMode(isVisible: true)
        deleteButton.isHidden = false
    }
    
    func editMode(isVisible: Bool) {
        if isVisible {
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseInOut], animations: {
                
                self.addEventButton.isHidden = true
                self.topEditModeContainer.frame.origin.y = 0
                self.bottomEditModeContainer.frame.origin.y = self.view.frame.maxY - 70
                self.leftHandle.isHidden = false
                self.rightHandle.isHidden = false
                self.eventViewInFocus.layer.opacity = 0.75
                
            }, completion: { _ in
                self.editModeIsOn = true
            })
        } else {
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseInOut], animations: {
                
                self.addEventButton.isHidden = false
                self.topEditModeContainer.frame.origin.y = -self.topEditModeContainer.frame.height
                self.bottomEditModeContainer.frame.origin.y = self.view.frame.maxY
                self.leftHandle.isHidden = true
                self.rightHandle.isHidden = true
                self.eventViewInFocus.layer.opacity = 1

                
            }, completion: { _ in
                self.editModeIsOn = false
            })
            
        }
    }
    
    func changeStartDate() {
        print("changeStartDate()")
    }
    
    func changeEndDate() {
        print("endStartDate()")
    }
    
    func tap() {
        print("tap")
    }
    
    //MARK: ------------------------------------------------------------ save & cancel ---------------------------------------------------------------------------
    
    
    func cancelButtonPressed() {
        print("cancel")
        if eventViewInFocus.isNewEvent == false {
            eventViewInFocus.layer.opacity = 1
            let minutes = eventViewInFocus.event.startDate.minutes(from: Calendar.current.date(from: DateComponents(year: 2017, month: eventViewInFocus.month+1, day: eventViewInFocus.day+1))!)
            let duration = eventViewInFocus.event.endDate.minutes(from: eventViewInFocus.event.startDate)
            let x = minuteAsPercentage * CGFloat(minutes)
            eventViewInFocus.frame = CGRect(x: x, y: eventY, width: CGFloat(duration) * minuteAsPercentage, height: eventHeight)
        } else {
            eventViewInFocus.removeFromSuperview()
        }
        editMode(isVisible: false)
        eventTitleTextField.text = nil
        eventViewInFocus = nil
        resize()
    }
    
    func deleteButtonPressed() {
        print("delete")
        let optionMenu = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            //Your code here to respond to this choice
            self.delete(eventView: self.eventViewInFocus)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Action Cancelled")
        })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func saveButtonPressed() {
        print("save")
        if eventTitleTextField.text == "" || eventTitleTextField.text == nil {
            print("its empty")
            let alert = UIAlertController(title: "No Title", message: "Set a title for the event in order to save it.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            
            return
        } else if (eventViewInFocus.event?.startDate == dateFormatter.date(from: startDateLabel.text!)! && eventViewInFocus.event?.endDate == dateFormatter.date(from: endDateLabel.text!)! && eventViewInFocus.text == eventTitleTextField.text!) {
            print("no changes detected")
            cancelButtonPressed()
            return
        }
        
        if eventViewInFocus.isNewEvent {
            let eventStore = EKEventStore()
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.title = eventTitleTextField.text!
            newEvent.startDate = dateFormatter.date(from: startDateLabel.text!)!
            newEvent.endDate = dateFormatter.date(from: endDateLabel.text!)!
            newEvent.calendar = eventStore.calendar(withIdentifier: eventStore.defaultCalendarForNewEvents.calendarIdentifier)!
            newEvent.addAlarm(EKAlarm(absoluteDate: newEvent.startDate))
            newEvent.notes = "Event created with Perspektive"
            do {
                try eventStore.save(newEvent, span: .thisEvent, commit: true)
                eventViewInFocus.removeFromSuperview()
                eventViewInFocus = EventView(event: newEvent)
                self.yearView.months[eventViewInFocus.month].eventViews.append(eventViewInFocus)
                eventViewInFocus.countInMonth = self.yearView.months[eventViewInFocus.month].eventViews.count-1
                self.yearView.months[eventViewInFocus.month].days[eventViewInFocus.day].eventViews.append(eventViewInFocus)
                eventViewInFocus.countInDay = self.yearView.months[eventViewInFocus.month].days[eventViewInFocus.day].eventViews.count-1
                resize()
                cancelButtonPressed()
            } catch {
                let alert = UIAlertController(title: "Event could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let eventStore = EKEventStore()
            let existingEvent: EKEvent? = eventStore.event(withIdentifier: eventViewInFocus.identifier!)
            existingEvent!.title = eventTitleTextField.text!
            existingEvent!.startDate = dateFormatter.date(from: startDateLabel.text!)!
            existingEvent!.endDate = dateFormatter.date(from: endDateLabel.text!)!
            do {
                try eventStore.save(existingEvent!, span: .thisEvent, commit: true)
                eventViewInFocus.event = existingEvent
                cancelButtonPressed()
            } catch {
                let alert = UIAlertController(title: "Event could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func dragged() {
        if !editModeIsOn {
            return
        }
        
        print("dragged")
        
        switch dragGesture.state {
        case .began:
            let location = dragGesture.location(in: containerView)
            if leftHandle.frame.contains(location) {
                viewToDrag = leftHandle
            } else if rightHandle.frame.contains(location) {
                viewToDrag = rightHandle
            } else {
                viewToDrag = nil
            }
        case .changed:
            if viewToDrag != nil {
                if eventViewInFocus.frame.width < 10 {
                    return
                }
                
                if viewToDrag == leftHandle {
                    let lastXPos = leftHandle.center.x
                    leftHandle.center.x = dragGesture.location(in: containerView).x
                    eventViewInFocus.frame.origin.x += (leftHandle.center.x - lastXPos)
                    eventViewInFocus.frame.size.width -= (leftHandle.center.x - lastXPos)
                    
                    //change start label
                    let eventMinX = eventViewInFocus.superview!.convert(CGPoint(x: eventViewInFocus.frame.minX, y: eventViewInFocus.frame.midY), to: containerView).x
                    let minutes = minutesInYear * (eventMinX/yearView.frame.width) * 60 //seconds
                    let startDate = Date(timeInterval: TimeInterval(minutes), since: y2017)
                    startDateLabel.text = dateFormatter.string(from: startDate)
                    
                } else if viewToDrag == rightHandle {
                    rightHandle.center.x = dragGesture.location(in: containerView).x
                    eventViewInFocus.frame.size.width = dragGesture.location(in: containerView).x - containerView.convert(eventViewInFocus.frame.origin, from: eventViewInFocus.superview).x
                    
                    //change end label
                    let eventMaxX = eventViewInFocus.superview!.convert(CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY), to: containerView).x //+ eventViewInFocus.bounds.width
                    let minutes = minutesInYear * (eventMaxX/yearView.frame.width) * 60 //seconds
                    let endDate = Date(timeInterval: TimeInterval(minutes), since: y2017)
                    endDateLabel.text = dateFormatter.string(from: endDate)
                }
            }
        case .ended:
            viewToDrag = nil
        default:
            viewToDrag = nil
        }
    }
    
    func draggedToZoom() {
        
    }
    
    func longPressed() {
        print("longpressed")
        
        if longPressGesture.state == .began && (eventViewInFocus?.frame.contains(longPressGesture.location(in: eventViewInFocus.superview)) ?? false) {
            longPressGestureLastLocation = longPressGesture.location(in: eventViewInFocus.superview)
            editMode(isVisible: true)
            longPressStartedOnEventInFocus = true
        } else if longPressGesture.state == .changed && longPressStartedOnEventInFocus {
            eventViewInFocus.center.x += longPressGesture.location(in: eventViewInFocus.superview).x - longPressGestureLastLocation.x
            leftHandle.center = containerView.convert(CGPoint(x: eventViewInFocus.frame.minX, y: eventViewInFocus.frame.midY), from: eventViewInFocus.superview)
            let endPoint = CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY)
            rightHandle.center = containerView.convert(endPoint, from: eventViewInFocus.superview)
            longPressGestureLastLocation = longPressGesture.location(in: eventViewInFocus.superview)
            
            //change start label
            let eventMinX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x
            let startMinutes = minutesInYear * (eventMinX/yearView.frame.width) * 60 //seconds
            let startDate = Date(timeInterval: TimeInterval(startMinutes), since: y2017)
            startDateLabel.text = dateFormatter.string(from: startDate)
            
            //change end label
            let eventMaxX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x + eventViewInFocus.bounds.width
            let endMinutes = minutesInYear * (eventMaxX/yearView.frame.width) * 60 //seconds
            let endDate = Date(timeInterval: TimeInterval(endMinutes), since: y2017)
            endDateLabel.text = dateFormatter.string(from: endDate)
        } else if longPressGesture.state == .began && !(editModeIsOn || yearView.frame.width/12/31 <= view.frame.width) && gestureTouch!.view!.isKind(of: Hour.self) {
            let newEventView = EventView()
            newEventView.frame.size = CGSize(width: middleHour!.frame.width, height: eventHeight)
            newEventView.frame.origin.x = containerView.convert(gestureTouch!.view!.frame.origin, from: gestureTouch!.view!.superview!).x
            newEventView.frame.origin.y = 175
            newEventView.layoutSubviews()
            newEventView.text = "New Event..."
            newEventView.isNewEvent = true
            containerView.addSubview(newEventView)
            leftHandle.removeFromSuperview()
            containerView.addSubview(leftHandle)
            rightHandle.removeFromSuperview()
            containerView.addSubview(rightHandle)
            eventViewInFocus = newEventView
            leftHandle.center.x = containerView.convert(eventViewInFocus.frame.origin, from: eventViewInFocus.superview).x
            leftHandle.center.y = containerView.convert(eventViewInFocus.center, from: eventViewInFocus.superview).y
            let endPoint = CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY)
            rightHandle.center = containerView.convert(endPoint, from: eventViewInFocus.superview)
            
            //change start label
            let eventMinX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x
            let startMinutes = minutesInYear * (eventMinX/yearView.frame.width) * 60 //seconds
            let startDate = Date(timeInterval: TimeInterval(startMinutes), since: y2017)
            startDateLabel.text = dateFormatter.string(from: startDate)
            
            //change end label
            let eventMaxX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x + eventViewInFocus.bounds.width
            let endMinutes = minutesInYear * (eventMaxX/yearView.frame.width) * 60 //seconds
            let endDate = Date(timeInterval: TimeInterval(endMinutes), since: y2017)
            endDateLabel.text = dateFormatter.string(from: endDate)
            
            editMode(isVisible: true)
            longPressStartedOnEventInFocus = true
            longPressGestureLastLocation = longPressGesture.location(in: eventViewInFocus.superview)
        } else if longPressGesture.state == .ended {
            longPressStartedOnEventInFocus = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if isEditing && !eventTitleTextField.frame.contains(touch.location(in: view)) {
            self.view.endEditing(true)
        }
        
        gestureTouch = touch
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureTouch?.view == leftHandle || gestureTouch?.view == rightHandle {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //        eventViewInFocus.text = textField.text
        view.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == eventTitleTextField {
            if textField.text!.characters.count + string.characters.count - range.length >= 51 {
                return false
            }
        }
        return true
    }
    
    func delete(eventView: EventView) {
        let eventStore = EKEventStore()
        do {
            let eventToDelete = eventStore.event(withIdentifier: eventViewInFocus.identifier!)
            try eventStore.remove(eventToDelete!, span: .thisEvent)
            self.yearView.months[eventView.month].eventViews[eventViewInFocus.countInMonth!].willBeDeleted = true
            self.yearView.months[eventView.month].days[eventView.day].eventViews[eventViewInFocus.countInDay!].willBeDeleted = true
            
            eventViewInFocus.removeFromSuperview()
            cancelButtonPressed()
        } catch {
            let alert = UIAlertController(title: "Event could not be deleted", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func addEvent() {
        if editModeIsOn || yearView.frame.width/12/31 <= view.frame.width {
            return
        }
        let newEventView = EventView()
        newEventView.frame.size = CGSize(width: middleHour!.frame.width, height: eventHeight)
        newEventView.frame.origin.x = middleHour!.superview!.convert(middleHour!.frame.origin, to: containerView).x
        newEventView.center.y = middleHour!.center.y + 40
        newEventView.layoutSubviews() //for cornerradius
        newEventView.text = "New Event..."
        newEventView.isNewEvent = true
        containerView.addSubview(newEventView)
        leftHandle.removeFromSuperview()
        containerView.addSubview(leftHandle)
        rightHandle.removeFromSuperview()
        containerView.addSubview(rightHandle)
        eventViewInFocus = newEventView
        leftHandle.center = containerView.convert(CGPoint(x: eventViewInFocus.frame.minX, y: eventViewInFocus.frame.midY), from: eventViewInFocus.superview)
        let endPoint = CGPoint(x: eventViewInFocus.frame.maxX, y: eventViewInFocus.frame.midY)
        rightHandle.center = containerView.convert(endPoint, from: eventViewInFocus.superview)
        
        //change start label
        let eventMinX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x
        let startMinutes = minutesInYear * (eventMinX/yearView.frame.width) * 60 //seconds
        let startDate = Date(timeInterval: TimeInterval(startMinutes), since: y2017)
        startDateLabel.text = dateFormatter.string(from: startDate)
        
        //change end label
        let eventMaxX = eventViewInFocus.superview!.convert(eventViewInFocus.frame.origin, to: containerView).x + eventViewInFocus.bounds.width
        let endMinutes = minutesInYear * (eventMaxX/yearView.frame.width) * 60 //seconds
        let endDate = Date(timeInterval: TimeInterval(endMinutes), since: y2017)
        endDateLabel.text = dateFormatter.string(from: endDate)
        
        editMode(isVisible: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //width percentage change
        self.sizePercentage = CGSize(width: size.width/self.view.frame.width, height: size.height/self.view.frame.height)
        
        if size.width > size.height {
            //change to landscape mode
            //size = coming size
            if !editModeIsOn {
                topEditModeContainer.isHidden = true
                bottomEditModeContainer.isHidden = true
            }
            
            coordinator.animate(alongsideTransition: { (_ context: Any) in
                
                //containerView
                self.containerView.frame = CGRect(x: 0, y: size.height*1/8, width: size.width, height: size.height*2/3)
                self.containerView.scrollIndicatorInsets.bottom = 0
                //editmodecontainer
                if self.editModeIsOn {
                    self.topEditModeContainer.frame = CGRect(x: 0, y: 0, width: size.width, height: 85)
                    self.bottomEditModeContainer.frame = CGRect(x: 0, y: size.height-70, width: size.width, height: 70)
                } else {
                    self.topEditModeContainer.frame = CGRect(x: 0, y: -85, width: size.width, height: 85)
                    self.bottomEditModeContainer.frame = CGRect(x: 0, y: size.height, width: size.width, height: 70)
                }
                //addevent Button
                self.addEventButton.frame.origin = CGPoint(x: size.width - 75, y: 30)
                //editEvent label
                self.editEventLabel.isHidden = true
                //eventLocation label
                self.eventLocationLabel.frame.origin = CGPoint(x: 20, y: 30)
                //containerView
                self.eventTitleTextField.frame = CGRect(x: 10, y: 10, width: size.width - 20, height: self.eventTitleTextField.frame.height)
                //startDate label
                self.startDateLabel.frame.origin = CGPoint(x: size.width/2 - self.startDateLabel.frame.width, y: 55)
                //until label
                self.untilLabel.frame.origin = CGPoint(x: size.width/2 - self.untilLabel.frame.width/2, y: 65)
                //endDate label
                self.endDateLabel.frame.origin = CGPoint(x: size.width/2, y: 55)
                //delete button
                self.deleteButton.frame = CGRect(x: 20, y: 0, width: 100, height: 50)
                //cancel button
                self.cancelButton.frame = CGRect(x: self.bottomEditModeContainer.bounds.midX-40, y: 10, width: 80, height: 40)
                //save button
                self.saveButton.frame = CGRect(x: self.bottomEditModeContainer.bounds.maxX - 120, y: 0, width: 100, height: 50)
                
            } , completion: { ( _ context: Any) in
                self.topEditModeContainer.isHidden = false
                self.bottomEditModeContainer.isHidden = false
                
                //containerView subviews
                self.delta = 0
                self.eventY = 45
                self.eventHeight = 30
                self.pinched()//or pinched() ?

                print("now in landscape mode")
            } )
        } else {
            
            if !editModeIsOn {
                topEditModeContainer.isHidden = true
                bottomEditModeContainer.isHidden = true
            }
            
            //change to portrait mode
            coordinator.animate(alongsideTransition: { (_ context: Any) in
                
                self.containerView.frame.size = CGSize(width: size.width, height: size.height * (2/3))
                self.containerView.center = CGPoint(x: size.width/2, y: size.height/2 + 40)
                self.containerView.scrollIndicatorInsets.bottom = 40
                self.addEventButton.frame = CGRect(x: size.width-60, y: 45, width: 30, height: 30)
                if self.editModeIsOn {
                    self.topEditModeContainer.frame = CGRect(x: 0, y: 0, width: size.width, height: self.containerView.frame.minY)
                    self.bottomEditModeContainer.frame = CGRect(x: 0, y: self.containerView.frame.maxY, width: size.width, height: size.height - self.containerView.frame.maxY)
                } else {
                    self.topEditModeContainer.frame = CGRect(x: 0, y: -self.containerView.frame.minY, width: size.width, height: self.containerView.frame.minY)
                    self.bottomEditModeContainer.frame = CGRect(x: 0, y: size.height, width: size.width, height: 70)
                }
                self.editEventLabel.isHidden = false
                self.editEventLabel.center.x = size.width/2
                self.editEventLabel.frame.origin.y = 30
                self.eventLocationLabel.frame = CGRect(x: 25, y: 55, width: 200, height: 20)
                self.eventTitleTextField.frame = CGRect(x: 20, y: 65, width: size.width-40, height: 45)
                self.startDateLabel.frame = CGRect(x: 25, y: 110, width: 150, height: 40)
                self.untilLabel.frame.origin = CGPoint(x: size.width/2-self.untilLabel.bounds.midX, y: 120)
                self.endDateLabel.frame = CGRect(x: self.eventTitleTextField.frame.maxX-155, y: 110, width: 150, height: 40)
                self.deleteButton.frame = CGRect(x: 20, y: 0, width: 100, height: 50)
                self.cancelButton.frame = CGRect(x: self.bottomEditModeContainer.bounds.midX-40, y: 10, width: 80, height: 40)
                self.saveButton.frame = CGRect(x: self.bottomEditModeContainer.bounds.maxX - 120, y: 0, width: 100, height: 50)
                
            } , completion: { ( _ context: Any) in
                self.topEditModeContainer.isHidden = false
                self.bottomEditModeContainer.isHidden = false
                
                //containerView subviews
                self.delta = 0
                self.eventY = 60
                self.eventHeight = 60
                self.pinched()//or pinched() ?
                print("now in portrait mode")
            } )
        }
        
        
        
    }
}
