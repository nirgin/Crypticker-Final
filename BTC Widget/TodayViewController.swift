/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import NotificationCenter
import CryptoCurrencyKit

class TodayViewController: CurrencyDataViewController, NCWidgetProviding {
  
  var lineChartIsVisible = false;
  @IBOutlet weak var toggleLineChartButton: UIButton!
  @IBOutlet weak var lineChartHeightConstraint: NSLayoutConstraint!
  
  @IBAction func toggleLineChart(_ sender: UIButton) {
    if lineChartIsVisible {
      lineChartHeightConstraint.constant = 0
      let transform = CGAffineTransform(rotationAngle: 0)
      toggleLineChartButton.transform = transform
      lineChartIsVisible = false
    } else {
      lineChartHeightConstraint.constant = 98
      let transform = CGAffineTransform(rotationAngle: CGFloat(180.0 * M_PI/180.0))
      toggleLineChartButton.transform = transform
      lineChartIsVisible = true
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    lineChartHeightConstraint.constant = 0
    
    lineChartView.delegate = self;
    lineChartView.dataSource = self;
    
    priceLabel.text = "--"
    priceChangeLabel.text = "--"
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    fetchPrices { error in
      if error == nil {
        self.updatePriceLabel()
        self.updatePriceChangeLabel()
        self.updatePriceHistoryLineChart()
      }
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updatePriceHistoryLineChart()
  }
  
  func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
    return UIEdgeInsets.zero
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    fetchPrices { error in
      if error == nil {
        self.updatePriceLabel()
        self.updatePriceChangeLabel()
        self.updatePriceHistoryLineChart()
        completionHandler(.newData)
      } else {
        completionHandler(.noData)
      }
    }
  }
  
  override func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
    return UIColor(red: 0.17, green: 0.49, blue: 0.82, alpha: 1.0)
  }
  
}
