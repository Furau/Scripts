//
//  AboutCenterView.swift
//  BeautifulApp
//
//  Created by 梁亦明 on 15/11/28.
//  Copyright © 2015年 xiaoming. All rights reserved.
//

import UIKit
protocol AboutCenterViewDelegate {
    func AboutCenterViewOfficialWebViewDidClick()
    func AboutCenterViewWechatViewDidClick()
    func AboutCenterViewExonerateViewDidClick()
    func AboutCenterViewUserAgreementDidClick()
}

class AboutCenterView: UIView {

    @IBOutlet weak var officialWebView: XMView!
    @IBOutlet weak var wechatView: XMView!
    @IBOutlet weak var exonerateView: XMView!
    @IBOutlet weak var userAgreement: XMView!
    var delegate : AboutCenterViewDelegate?
    
    class func centerView () -> AboutCenterView {
        return Bundle.main.loadNibNamed("AboutCenterView", owner: nil, options: nil)!.first as! AboutCenterView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.officialWebView.viewAddTarget(self, action: "officialWebViewDidClick")
        self.wechatView.viewAddTarget(self, action: "wechatViewDidClick")
        self.exonerateView.viewAddTarget(self, action: "exonerateViewDidClick")
        self.userAgreement.viewAddTarget(self, action: "userAgreementDidClick")
    }
    
    func officialWebViewDidClick() {
        self.delegate?.AboutCenterViewOfficialWebViewDidClick()
    }
    func wechatViewDidClick() {
        self.delegate?.AboutCenterViewWechatViewDidClick()
    }
    func exonerateViewDidClick() {
        self.delegate?.AboutCenterViewExonerateViewDidClick()
    }
    func userAgreementDidClick() {
        self.delegate?.AboutCenterViewUserAgreementDidClick()
    }

}
