import UIKit

@IBDesignable
class OptionButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.shadow(color: .lightGray, offSet: CGSize(width: 3, height: 3), opacity: 0.7, radius: self.frame.size.height / 2.0, scale: true)
        //self.setImage(UIImage(named: "camera"), for: .normal)
        //self.imageEdgeInsets = UIEdgeInsets(top: 1, left:5, bottom: 1, right: 1)
    }
}
