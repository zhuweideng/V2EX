import UIKit

class TopicCommentCell: BaseTableViewCell {

    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var usernameLaebl: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.hex(0xA3A3A3)
        return view
    }()

    private lazy var floorLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.hex(0xA3A3A3)
        return view
    }()

    private lazy var hostLabel: UILabel = {
        let view = UILabel()
        view.text = "楼主"
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.hex(0x969696)
        view.isHidden = true
        return view
    }()

    private lazy var contentTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 15)
        view.isEditable = false
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0)
        view.textContainer.lineFragmentPadding = 0
        view.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue : Theme.Color.linkColor]
        view.delegate = self
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Color.borderColor
        return view
    }()

    public var tapHandle: ((_ type: TapType) -> Void)?

    public var hostUsername: String?

    public var comment: CommentModel? {
        didSet {
            guard let `comment` = comment else { return }

            avatarView.setImage(urlString: comment.member.avatarSrc)
            usernameLaebl.text = comment.member.username
            floorLabel.text = comment.floor + " 楼"
            timeLabel.text =  comment.publicTime
            //            contentTextView.text = comment.content

            let html = "<style>\(cssStyle)</style>" + comment.content
            contentTextView.attributedText = html.html2AttributedString

            hostLabel.isHidden = hostUsername ?? ""  != comment.member.username
        }
    }

    private var cssStyle =
    """
        a:link, a:visited, a:active {
            text-decoration: none;
            word-break: break-all;
        }
        .reply_content {
            font-size: 14px;
            line-height: 1.6;
            color: #000;
            word-break: break-all;
            word-wrap: break-word;
        }
    """

    override func initialize() {
        selectionStyle = .none
        
        let avatarTapGesture = UITapGestureRecognizer()
        avatarView.addGestureRecognizer(avatarTapGesture)
        
        avatarTapGesture.rx
            .event
            .subscribeNext { [weak self] _ in
                guard let member = self?.comment?.member else { return }
                self?.tapHandle?(.member(member))
            }.disposed(by: rx.disposeBag)
        
        contentView.addSubviews(
            avatarView,
            usernameLaebl,
            timeLabel,
            floorLabel,
            hostLabel,
            contentTextView,
            lineView
        )
    }

    override func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.left.top.equalToSuperview().inset(15)
            $0.size.equalTo(48)
        }

        usernameLaebl.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(10)
            $0.top.equalTo(avatarView).offset(3)
        }

        hostLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLaebl.snp.right).offset(10)
            $0.centerY.equalTo(usernameLaebl)
        }

        floorLabel.snp.makeConstraints {
            $0.left.equalTo(usernameLaebl)
            $0.bottom.equalTo(avatarView).inset(3)
        }

        timeLabel.snp.makeConstraints {
            $0.left.equalTo(floorLabel.snp.right).offset(10)
            $0.centerY.equalTo(floorLabel)
        }

        contentTextView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview().inset(15)
            $0.top.equalTo(avatarView.snp.bottom).offset(10)
        }

        lineView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }
}

extension TopicCommentCell: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return interactHook(URL)
    }

    func interactHook(_ URL: URL) -> Bool {
        let link = URL.absoluteString
        if link.hasPrefix("https://") || link.hasPrefix("http://"){
            tapHandle?(.webpage(URL))
        } else if URL.path.contains("/member/") {
            let href = URL.path
            let name = href.lastPathComponent
            let member = MemberModel(username: name, url: href, avatar: "")
            tapHandle?(.member(member))
        } else if URL.path.contains("/t/") {
            let href = URL.path
            tapHandle?(.topic(href))
        } else if URL.path.contains("/go/") {
            tapHandle?(.node(NodeModel(name: "", href: URL.path)))
        }
        return false
    }

    //    @available(iOS 10.0, *)
    //    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    //        if textAttachment is ImageAttachment {
    //            let attachment = textAttachment as! ImageAttachment
    //            if let src = attachment.src, attachment.imageSize.width > 50 {
    //                linkTap?(TapLink.image(src: src))
    //            }
    //            return false
    //        }
    //        return true
    //    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: Data(utf8),
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            log.error("error:", error)
            return nil
        }
    }

    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
