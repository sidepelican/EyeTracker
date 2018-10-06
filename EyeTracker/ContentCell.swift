//
//  ContentCell.swift
//  EyeTracker
//
//  Created by kenta on 2018/10/05.
//

import UIKit

class ContentCell: UITableViewCell {
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        innerView.layer.cornerRadius = 8.0
        innerView.layer.shadowColor = UIColor.lightGray.cgColor
        innerView.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        innerView.layer.shadowOpacity = 0.7
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        contentView.backgroundColor = .white
        innerView.backgroundColor = highlighted ? .lightGray : .white
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return innerView.hitTest(point, with: event)
    }
}
