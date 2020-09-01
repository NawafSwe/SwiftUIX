//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || targetEnvironment(macCatalyst)

import MessageUI
import Foundation
import SwiftUI

/// A view whose interface lets the user manage, edit, and send email messages.
public struct MailComposer: UIViewControllerRepresentable {
    public struct Attachment: Codable, Hashable {
        fileprivate let data: Data
        fileprivate let mimeType: String
        fileprivate let fileName: String
        
        public init(data: Data, mimeType: String, fileName: String) {
            self.data = data
            self.mimeType = mimeType
            self.fileName = fileName
        }
    }
    
    fileprivate struct Configuration {
        var subject: String?
        var toRecipients: [String]?
        var ccRecipients: [String]?
        var bccRecipients: [String]?
        var messageBody: String?
        var messageBodyIsHTML: Bool = false
        var attachments: [Attachment] = []
        var preferredSendingEmailAddress: String?
    }
    
    fileprivate let onCompletion: (MFMailComposeResult, Error?) -> Void
    fileprivate var configuration = Configuration()
    
    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        MFMailComposeViewController()
    }
    
    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        context.coordinator.onCompletion = onCompletion
        
        uiViewController.mailComposeDelegate = context.coordinator
        
        uiViewController.configure(with: configuration, context: context)
    }
    
    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var onCompletion: (MFMailComposeResult, Error?) -> Void
        var addedAttachmentHashes = Set<Int>()
        
        init(onCompletion: @escaping (MFMailComposeResult, Error?) -> Void) {
            self.onCompletion = onCompletion
        }
        
        public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onCompletion(result, error)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
}

// MARK: - API -

extension MailComposer {
    public init(onCompletion: @escaping (MFMailComposeResult, Error?) -> Void) {
        self.onCompletion = onCompletion
    }
    
    public init() {
        self.init(onCompletion: { _, _ in })
    }
    
    public func subject(_ subject: String) -> Self {
        then({ $0.configuration.subject = subject })
    }
    
    public func toRecipients(_ toRecipients: [String]) -> Self {
        then({ $0.configuration.toRecipients = toRecipients })
    }
    
    public func ccRecipients(_ ccRecipients: [String]) -> Self {
        then({ $0.configuration.ccRecipients = ccRecipients })
    }
    
    public func bccRecipients(_ bccRecipients: [String]) -> Self {
        then({ $0.configuration.bccRecipients = bccRecipients })
    }
    
    public func messageBody(_ body: String, isHTML: Bool = false) -> Self {
        then {
            $0.configuration.messageBody = body
            $0.configuration.messageBodyIsHTML = isHTML
        }
    }
    
    public func attachments(_ attachments: [Attachment]) -> Self {
        then({ $0.configuration.attachments = attachments })
    }
    
    public func attach(_ attachment: Attachment) -> Self {
        then({ $0.configuration.attachments.append(attachment) })
    }
}

// MARK: - Auxiliary Implementation -

extension MFMailComposeViewController {
    fileprivate func configure(with configuration: MailComposer.Configuration, context: MailComposer.Context) {
        if let subject = configuration.subject {
            setSubject(subject)
        }
        
        if let toRecipients = configuration.toRecipients {
            setToRecipients(toRecipients)
        }
        
        if let ccRecipients = configuration.ccRecipients {
            setCcRecipients(ccRecipients)
        }
        
        if let bccRecipients = configuration.bccRecipients {
            setBccRecipients(bccRecipients)
        }
        
        if let messageBody = configuration.messageBody {
            setMessageBody(messageBody, isHTML: configuration.messageBodyIsHTML)
        }
        
        for attachment in configuration.attachments {
            if !context.coordinator.addedAttachmentHashes.contains(attachment.hashValue) {
                addAttachmentData(
                    attachment.data,
                    mimeType: attachment.mimeType,
                    fileName: attachment.fileName
                )
                
                context.coordinator.addedAttachmentHashes.insert(attachment.hashValue)
            }
        }
    }
}

#endif