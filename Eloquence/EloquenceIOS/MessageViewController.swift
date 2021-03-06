import Foundation
import UIKit
import XMPPFramework
import JSQMessagesViewController
import MBProgressHUD


class MessageViewController:JSQMessagesViewController, UIActionSheetDelegate, JSQMessagesComposerTextViewPasteDelegate, EloChatDelegate {

    private var chat: EloChat?;
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.title = "";
        setupBubbles()

        /**
        @IBOutlet var adressLabel: NSTextField!
        @IBOutlet var adressLabel: NSTextField!
        *  You MUST set your senderId and display name
        */
        
        self.senderId = "foo"
        self.senderDisplayName = "foo"
        
 //       self.inputToolbar.contentView.textView.pasteDelegate = self;

        self.view!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageViewController.loadChat(_:)), name: EloConstants.ACTIVATE_CONTACT, object: nil)
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,  messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        
        if(chat != nil){
            let msg = chat!.getMessage(indexPath.item);
            return JSQMessage(senderId: msg.author, senderDisplayName:msg.author, date: NSDate(), text: msg.text )
        }else{
            return nil;
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(chat != nil){
            NSLog("Items %d",chat!.numberOfRowsInSection(0));
            return chat!.numberOfRowsInSection(0);
        }else {
            return 0;
        }
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
            return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
            let msg = chat!.getMessage(indexPath.item);// 1
            if msg.isOutgoing { // 2
                return outgoingBubbleImageView
            } else { // 3
                return incomingBubbleImageView
            }
    }
    
    private func getSafeChat() -> EloChat {
        return chat!
    }
    
    
    func loadChat(notification:NSNotification){

        let chatId = notification.object as! EloChatId
        
        chat = EloChats.sharedInstance.getChat(chatId.from, to: chatId.to);
        chat!.delegate = self;
        
        self.automaticallyScrollsToMostRecentMessage = false;
        
        let progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        progressHUD.labelText = "Loading History ..."
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.chat!.loadInitialArchive()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.finishReceivingMessageAnimated(false)
                progressHUD.hide(true)
                self.automaticallyScrollsToMostRecentMessage = true
            }
        }
        
        
    }
    
    //Mark: EloChatDelegate
    
    func didReceiveMessage(msg: EloMessage) {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            self.finishReceivingMessageAnimated(true)
        })

    }
    
    func didFailSendMessage(msg: EloMessage) {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.finishReceivingMessageAnimated(true)
        })
    }

    func chatWillChangeContent() {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.finishReceivingMessageAnimated(true)
        })
    }
    
    func chat(didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: EloFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.finishReceivingMessageAnimated(true)
        })    }
    
    func chatDidChangeContent() {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.finishReceivingMessageAnimated(true)
        })
    }
    
    
    //Mark: JSQMessagesComposerTextViewPasteDelegate
    
    func composerTextView(textView: JSQMessagesComposerTextView!, shouldPasteWithSender sender: AnyObject!) -> Bool {
        return true;
    }
    
    
    //Mark JSQMessagesViewController
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound();
        
        //let message = JSQMessage(senderId: senderId, senderDisplayName:senderDisplayName, date: date, text: text)
        //messages.append(message)
        
        do {
            try getSafeChat().sendTextMessage(text);
        }catch EloChatError.NotConnected {
            //TODO
        }catch {
            //TODO
        }
        
        finishSendingMessageAnimated(true)
        
        
        
    }
}