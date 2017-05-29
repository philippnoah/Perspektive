//
//  TutorialViewController.swift
//  Perspektive
//
//  Created by Philipp Eibl on 5/16/17.
//  Copyright © 2017 Philipp Eibl. All rights reserved.
//

import Foundation
import UIKit

class TutorialViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var doneButton: UIButton!
    @IBAction func doneButtonTouchDown(_ sender: UIButton) {
        
        let loadingScreen = UILabel()
        loadingScreen.text = "Loading..."
        loadingScreen.font = UIFont(name: "Quicksand-Bold", size: 20)
        loadingScreen.textAlignment = .center
        loadingScreen.textColor = UIColor.white
        loadingScreen.backgroundColor = UIColor.cyan
        loadingScreen.frame = view.bounds
        view.addSubview(loadingScreen)
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "finishTutorial", sender: nil)

        }
    }
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageArray = [#imageLiteral(resourceName: "Tutorial1"), #imageLiteral(resourceName: "Tutorial2"), #imageLiteral(resourceName: "Tutorial3"), #imageLiteral(resourceName: "Tutorial4"), #imageLiteral(resourceName: "Tutorial5"), #imageLiteral(resourceName: "Tutorial6")]
        scrollView.frame = view.bounds
        scrollView.contentSize = CGSize(width: CGFloat(imageArray.count) * view.frame.width, height: view.frame.height)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        doneButton.sizeToFit()
        doneButton.center = CGPoint(x: scrollView.contentSize.width-view.frame.width/2, y: view.frame.height-100)
        
        for i in 0...imageArray.count-1 {
            let imageView = UIImageView()
            imageView.image = imageArray[i]
            imageView.contentMode = .scaleAspectFit
            imageView.frame.size = view.bounds.size
            imageView.frame.origin = CGPoint(x: view.frame.width * CGFloat(i), y: 0)
            scrollView.addSubview(imageView)
        }
    }
}
